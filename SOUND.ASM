;==============================================================
;   TANGLEWOOD - A game by Matt Phillips - (c) 2017
;==============================================================
;   http://www.bigevilcorporation.co.uk
;==============================================================
;   sound.asm - High level sound routines
;==============================================================

AndTable:  
	dc.b $FF,$FF, $FF,$FE,$FF,$FD, $FF,$FF,$FF
OrTable:   
	dc.b $00,$00, $01,$00,$02,$00, $00,$00,$00

Echo_FMVolTable:
    dc.b    $7F,$7B,$77,$73,$70,$6C,$68,$65,$61,$5E,$5A,$57,$54,$50,$4D,$4A
    dc.b    $47,$44,$41,$3F,$3C,$39,$36,$34,$31,$2F,$2D,$2A,$28,$26,$24,$22
    dc.b    $20,$1E,$1C,$1A,$18,$16,$15,$13,$12,$10,$0F,$0D,$0C,$0B,$0A,$09
    dc.b    $08,$07,$06,$05,$04,$04,$03,$02,$02,$01,$01,$01,$00,$00,$00,$00

Echo_PSGVolTable:
    dc.b    $0F,$0F,$0E,$0E,$0D,$0D,$0C,$0C,$0B,$0B,$0B,$0A,$0A,$0A,$09,$09
    dc.b    $08,$08,$08,$07,$07,$07,$06,$06,$06,$06,$05,$05,$05,$04,$04,$04
    dc.b    $04,$03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01
    dc.b    $01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	IF ECHO_ENCRYPT_Z80
EchoDecryptKey:
	dc.b 0x2b, 0xcd, 0xc1, 0x9a, 0x80, 0x9c, 0x48, 0x81, 0x8c, 0x6c, 0x28, 0xaa, 0x43, 0xd0, 0xce, 0xa7
EchoDecryptKeyEnd
	ENDIF

; PCM frequencies (NTSC)
PCM_Freq_26632Hz	equ 0x1
PCM_Freq_17755Hz	equ 0x2
PCM_Freq_13316Hz	equ 0x3
PCM_Freq_10653Hz	equ 0x4
PCM_Freq_8877Hz		equ 0x5
PCM_Freq_7609Hz		equ 0x6
PCM_Freq_6658Hz		equ 0x7
PCM_Freq_5918Hz		equ 0x8
PCM_Freq_5326Hz		equ 0x9
PCM_Freq_4842Hz		equ 0xA
PCM_Freq_4439Hz		equ 0xB
PCM_Freq_4097Hz		equ 0xC

PCM_Freq_Default	equ PCM_Freq_10653Hz

; Track types in priority order
Track_Type_Cue			equ 0x0	; One-shot music cue (interrupts BGM/ambience)
Track_Type_BGM			equ 0x1	; Looping BGM
Track_Type_Threat		equ 0x2	; Enemy BGM
Track_Type_Ambience		equ 0x3	; Background ambience (mutually exclusive with BGM)
;------------------------------
Track_Type_COUNT		equ 0x4

; Track transition type
Track_Transition_Crossfade	equ 0x0	; Fade track A out, fade in track B
Track_Transition_Instant	equ 0x1	; Stop track A, begin track B
Track_Transition_FadeDown	equ 0x2	; Fade track A out, begin track B
Track_Transition_FadeUp		equ 0x3	; Stop track A, fade in track B

; SFX priority clash
SFX_PriorityClash_NoPlay	equ 0x0
SFX_PriorityClash_Replace	equ 0x1

Audio_NonExclusive		equ 0x0	; Non-excusive - plays alongside other SFX/tracks
Audio_Exclusive			equ 0x1	; Exclusive track - disallows other tracks/SFX

Audio_DefaultFadeSpeed	equ 0x1
Audio_MinFadeDownVol	equ 0x80	; Cut volume to 0 after fading this far

	rsset 0
Track_Data				rs.l 1
Track_ChannelMask		rs.w 1
Track_AutoStopTime		rs.w 1
Track_Type				rs.b 1
Track_Exclusive			rs.b 1
Track_PriorityOverSFX	rs.b 1
Track_Transition		rs.b 1
;-----------------------------
	RS_ALIGN
Track_Struct_Size		rs.b 0

	rsset 0
SFX_Data				rs.l 1
SFX_Priority			rs.b 1
SFX_Exclusive			rs.b 1
SFX_ClashBehaviour		rs.b 1
;-----------------------------
	RS_ALIGN
SFX_Struct_Size			rs.b 0

ESF_SetPCMRate: macro rate
	ESF_SetFMReg 0, $24, ((\rate)^$3FF)>>2
	ESF_SetFMReg 0, $25, ((\rate)^$3FF)&3
	endm

SND_Init:  ; addr 0x7E5C
	; Initialises Echo sound system and sets default values

	IF INCLUDE_AUDIO
	lea echo_instruments, a0
	jsr Echo_Init
	move.b #0xFF, audio_volume_global
	move.b #0x00, audio_fader_speed
	ENDIF

	rts

SND_GetSSGEGEnabled:
	; d0 (b) SSG-EG enabled
	move.b #0x0, d1
	IF INCLUDE_AUDIO
	jsr    Echo_GetSSGEGEnabled
	ENDIF
	rts

SND_EnableSSGEG:
	IF INCLUDE_AUDIO
	jsr    Echo_EnableSSGEG
	ENDIF
	rts

SND_DisableSSGEG:
	; Disables SGG-EG feature (screeches on machines that don't implement it properly)
	IF INCLUDE_AUDIO
	jsr    Echo_DisableSSGEG
	ENDIF
	rts

SND_PauseBGM:
	IF INCLUDE_AUDIO
	jsr    Echo_PauseBGM
	ENDIF
	rts

SND_ResumeBGM:
	IF INCLUDE_AUDIO
	jsr    Echo_ResumeBGM
	ENDIF
	rts

SND_PlayTrack:
	; a0 --- Track address
	
	IF INCLUDE_AUDIO

	PUSHL a1

	; Queue address
	move.l #0x0, a1

	;==============================================================

	; If exclusivity held, bail
	tst.b  audio_playback_locked
	bne    @Busy

	; Queue track
	moveq #0x0, d0
	move.b Track_Type(a0), d0
	lsl.l  #0x2, d0
	lea    audio_queued_tracks, a1
	add.l  d0, a1
	move.l a0, (a1)

	; If current track playing, fade out first
	tst.l  audio_current_track
	beq    @Free

	; Determine transition type
	move.b Track_Transition(a0), d0
	cmp.b  #Track_Transition_Instant, d0
	beq    @StopPrev
	cmp.b  #Track_Transition_FadeUp, d0
	beq    @StopPrev

	; All remaining transitions require fade out
	move.b #-Audio_DefaultFadeSpeed, d0
	jsr    SND_BeginFadeTrack

	; Bail, wait for track to finish fading out
	bra    @Busy

	@StopPrev:

	; Stop previous track instantly
	jsr    SND_StopTrack

	; Reset volume
	move.b #0xFF, d0
	jsr    SND_SetGlobalVolume

	; Reset fader
	move.b #0x0, audio_fader_speed

	@Free:

	;==============================================================

	; If not ambience, remove from queue
	cmpa.w #0x0, a1
	beq    @NotQueued
	cmp.b  #Track_Type_Ambience, Track_Type(a0)
	beq    @Ambience
	move.l #0x0, (a1)
	@NotQueued:
	@Ambience:

	; Store current track
	move.l a0, audio_current_track

	; Set exclusivity
	move.b Track_Exclusive(a0), audio_playback_locked

	; Set auto-stop timer
	move.w Track_AutoStopTime(a0), audio_track_stop_timer

	; Play track
	move.l Track_Data(a0), a0
	jsr    Echo_PlayBGM

	;==============================================================

	@Busy:

	POPL   a1

	ENDIF

	rts

SND_QueueTrack:
	; a0 --- Track address

	IF INCLUDE_AUDIO

	; Queue track
	moveq #0x0, d0
	move.b Track_Type(a0), d0
	lsl.l  #0x2, d0
	lea    audio_queued_tracks, a1
	add.l  d0, a1
	move.l a0, (a1)

	ENDIF

	rts

SND_StopTrack:
	IF INCLUDE_AUDIO
	PUSHL  a0
	jsr    Echo_StopBGM

	move.l audio_current_track, a0
	cmpa   #0x0, a0
	beq    @NoTrack
	moveq  #0x0, d0
	move.b Track_Type(a0), d0
	lsl.l  #0x2, d0
	lea    audio_queued_tracks, a0
	add.l  d0, a0
	move.l #0x0, (a0)
	@NoTrack:

	move.l #0x0, audio_current_track
	move.w #0x0, audio_track_stop_timer
	move.b #0x0, audio_playback_locked
	POPL   a0
	ENDIF
	rts

SND_StopTrackType:
	; d0 (b) Track type

	; If currently playing track, stop playing
	move.l audio_current_track, a2
	cmpa.w #0x0, a2
	beq    @NoTrack
	cmp.b  Track_Type(a2), d0
	bne    @NotCurrentTrack
	PUSHW  d0
	move.b #-Audio_DefaultFadeSpeed, d0
	jsr    SND_BeginFadeTrack
	POPW   d0
	@NoTrack:
	@NotCurrentTrack:

	; Remove from queue
	andi.l #0xFF, d0
	lsl.l  #0x2, d0
	lea    audio_queued_tracks, a2
	add.l  d0, a2
	move.l #0x0, (a2)

	rts

SND_ClearTracks:
	lea    audio_queued_tracks, a1
	move.w #Track_Type_COUNT-1, d0
	@TrackLp:
	move.l #0x0, (a1)
	dbra   d0, @TrackLp
	move.b #0x0, audio_playback_locked
	rts

SND_PlaySFX:
	; a0 --- SFX address

	IF INCLUDE_AUDIO

	PUSHL  d0
	PUSHL  a1

	; Auto-stop SFX that have reach the end
	; TODO: done here due to delay between Echo_StartTrack and Echo_GetStatus returning SFX Busy flag
	tst.l  audio_current_sfx
	beq    @EndStopCheck
	jsr    SND_GetSFXBusy
	tst.b  d0
	bne    @EndStopCheck
	move.l #0x0, audio_current_sfx
	@EndStopCheck:

	;==============================================================

	; If exclusivity held, bail
	tst.b  audio_playback_locked
	bne    @Busy

	;==============================================================

	; If SFX already playing
	tst.l  audio_current_sfx
	beq    @CheckTrackPriority

	; Check priority
	move.l (audio_current_sfx), a1
	move.b SFX_Priority(a1), d0
	cmp.b  SFX_Priority(a0), d0
	blt    @Busy
	bgt    @Replace

	; Priorities clash
	cmp.b  #SFX_PriorityClash_NoPlay, SFX_ClashBehaviour(a0)
	beq    @Busy

	;==============================================================

	@CheckTrackPriority:
	@Replace:

	; If track playing
	tst.l  audio_current_track
	beq    @Free

	; Check priority
	move.l (audio_current_track), a1
	move.b Track_PriorityOverSFX(a1), d0
	cmp.b  SFX_Priority(a0), d0
	blt    @Busy

	;==============================================================

	@Free:

	; Set current SFX
	move.l a0, audio_current_sfx

	; Set exclusivity
	; TODO: Track playing SFX to turn off exclusive flag when finished
	; move.b SFX_Exclusive(a0), audio_playback_locked

	; Get SFX data
	move.l SFX_Data(a0), a0

	; Play SFX
	jsr    Echo_PlaySFX

	@Busy:

	POPL   a1
	POPL   d0

	ENDIF

	rts

SND_StopSFX:

	IF INCLUDE_AUDIO
	jsr   Echo_StopSFX
	ENDIF

	move.l #0x0, audio_current_sfx

	rts

SND_GetEchoBusy:
	; d0 (b) OUT: Echo sound system busy

	IF INCLUDE_AUDIO
	jsr    Echo_GetStatus
	btst   #5, d0			; Bit 15 = Last Echoc ommand not yet processed
	bne    @Busy
	move.b #0x0, d0
	bra    @End
	@Busy:
	move.b #0x1, d0
	@End:
	ENDIF

	rts

SND_GetSFXBusy:
	; d0 (b) OUT: SFX playback busy

	IF INCLUDE_AUDIO
	jsr    Echo_GetStatus
	btst   #0, d0			; Bit 0 = SFX playing
	bne    @Busy
	move.b #0x0, d0
	bra    @End
	@Busy:
	move.b #0x1, d0
	@End:
	ENDIF

	rts

SND_GetTrackBusy:
	; d0 (b) OUT: Track playback busy

	IF INCLUDE_AUDIO
	jsr    Echo_GetStatus
	btst   #1, d0			; Bit 1 = BGM playing
	bne    @Busy
	move.b #0x0, d0
	bra    @End
	@Busy:
	move.b #0x1, d0
	@End:
	ENDIF

	rts

SND_SetGlobalVolume:
	; d0 (b) - Volume (0 = quietest, 255 = loudest)

	; Set global volume
	move.b d0, audio_volume_global

	; Mirror to Echo
	jsr    Echo_SetVolume

	rts

SND_SetChannelVolume:
	; d0 (b) - Volume (0 = quietest, 255 = loudest)
	; d1 (b) - Channel
	rts

SND_BeginFadeTrack:
	; d0 (b) - Fade speed (change per frame, linear)
	;          (+ve = set silent and begin fade up, -ve = set volume high and begin fade down)
	; d1 (w) - Channel mask

	; Set fader speed
	move.b d0, audio_fader_speed

	; Determine direction
	tst.b  d0
	bgt    @FadeUp
	blt    @FadeDown
	bra    @End

	@FadeUp:
	; Fading up, set volume to 0
	move.b #0x00, d0
	jsr    SND_SetGlobalVolume
	bra    @End

	@FadeDown:
	; Fading down, set volume to 255
	move.b #0xFF, d0
	jsr    SND_SetGlobalVolume

	@End:

	rts

SND_Update:
	jsr SND_UpdateFader
	jsr SND_UpdateTrack
	rts

SND_UpdateFader:
	; Updates fader

	; Get fader and volume
	move.b (audio_fader_speed), d0
	move.b (audio_volume_global), d1

	; Determine direction
	tst.b  d0
	bgt    @FadeUp
	blt    @FadeDown
	bra    @End

	@FadeUp:
	; Fading up, clamp to 255
	add.b  d0, d1
	bcs    @NoClamp255
	move.b #0x00, d0		; Turn fader off
	move.b #0xFF, d1		; Clamp vol
	@NoClamp255:
	bra    @Apply

	@FadeDown:
	; Fading down, clamp to min and stop
	add.b  d0, d1
	cmp.b  #Audio_MinFadeDownVol, d1
	bhi    @NoClamp
	move.b #0x00, d0		; Turn fader off
	move.b #0xFF, d1		; Reset vol
	jsr    SND_StopTrack	; Stop playback
	@NoClamp:

	@Apply:

	; Put new fader value back
	move.b d0, audio_fader_speed

	; Set new volume
	move.b d1, d0
	jsr    SND_SetGlobalVolume

	@End:

	rts

SND_UpdateTrack:

	; If sound system not busy
	jsr    SND_GetEchoBusy
	tst.b  d0
	bne    @Busy

	;==============================================================

	; Check if track stopped
	tst.l  audio_current_track
	bne    @Busy

	; Determine next track
	lea    audio_queued_tracks, a1
	move.w #Track_Type_COUNT-1, d0
	@TrackCheckLp:
	tst.l  (a1)
	bne    @FoundTrack
	lea    size_long(a1), a1
	dbra   d0, @TrackCheckLp
	bra    @Silence

	@FoundTrack:

	; Fetch track address
	move.l (a1), a0

	; If not ambience, remove from queue
	cmp.b  #Track_Type_Ambience, Track_Type(a0)
	beq    @NoRemove
	move.l #0x0, (a1)
	@NoRemove:

	; Determine transition type
	move.b Track_Transition(a0), d0
	cmp.b  #Track_Transition_Crossfade, d0
	beq    @FadeUp
	cmp.b  #Track_Transition_FadeUp, d0
	beq    @FadeUp
	bra    @ResetVolume

	@FadeUp:
	
	; Start fader
	move.b #Audio_DefaultFadeSpeed, d0
	jsr    SND_BeginFadeTrack
	bra    @Play

	@ResetVolume:

	; else reset volume
	move.b #0xFF, d0
	jsr    SND_SetGlobalVolume

	; Reset fader
	move.b #0x0, audio_fader_speed

	@Play:

	; Play
	jsr    SND_PlayTrack

	bra    @Played

	@Busy:
	@Silence:

	;==============================================================

	; Auto-stop track if timer elapsed
	move.l (audio_current_track), a0
	cmpa.w #0x0, a0
	beq    @NoCurrentTrack
	move.w audio_track_stop_timer, d0
	beq    @TimerNotRunning
	subq.w  #0x1, d0
	move.w d0, audio_track_stop_timer
	tst.w  d0
	bne    @TimerRunning

	; Determine transition type
	move.b Track_Transition(a0), d0
	cmp.b  #Track_Transition_Crossfade, d0
	beq    @FadeDown
	cmp.b  #Track_Transition_FadeDown, d0
	beq    @FadeDown
	bra    @StopImmediate

	@FadeDown:
	
	; Start fading down
	move.b #-Audio_DefaultFadeSpeed, d0
	jsr    SND_BeginFadeTrack
	bra    @Stopped

	@StopImmediate:

	; else just stop track
	jsr    SND_StopTrack

	@Stopped:

	; Remove from queue
	moveq  #0x0, d0
	move.b Track_Type(a0), d0
	lsl.l  #0x2, d0
	lea    audio_queued_tracks, a2
	add.l  d0, a2
	move.l #0x0, (a2)

	@NoCurrentTrack:
	@TimerRunning:
	@TimerNotRunning:

	;==============================================================

	; Auto-stop tracks that have reach the end
	tst.l  audio_current_track
	beq    @EndStopCheck
	jsr    SND_GetEchoBusy	; If Echo is busy, check again later
	tst.b  d0
	bne    @EndStopCheck
	jsr    SND_GetTrackBusy
	tst.b  d0
	bne    @EndStopCheck
	move.l #0x0, audio_current_track
	move.b #0x0, audio_playback_locked
	move.b #0xFF, d0
	jsr    SND_SetGlobalVolume
	@EndStopCheck:

	;==============================================================

	@Played:

	rts

	Echo_StopSFX:
    move.w  d0, -(sp)               ; Save register
    move.b  #$03, d0                ; Command $03 = stop SFX
    bsr     Echo_SendCommand        ; Send command to Echo
    move.w  (sp)+, d0               ; Restore register
    
    rts   

	Echo_GetStatus:
    movem.l d1-d2/a1, -(sp)            ; Save registers

    clr.w   d0                      ; Set all needed bits to 0
    Echo_Z80Request                 ; We need the Z80 bus
    move.b  ($A01FF0), d0           ; Get the status flags

    tst.b   ($A01FFB)               ; Check if any commands can be sent
    beq.s   @NotBusy                ; Any room left for new commands?
    bset.l  #15, d0                 ; If not, set the relevant flag
@NotBusy:

    cmpi.b  #$FF, ($A01F00)         ; Check if the direct buffer is empty
    beq.s   @DirectEmpty            ; Any direct events still to be played?
    bset.l  #14, d0                 ; If so, set the relevant flag
@DirectEmpty:

    moveq   #0, d1                  ; Clear unused bits from index
    lea     AndTable(pc), a1       ; Get pointer to look-up tables
    
    move.b  ($A01FFF), d1           ; Get next pending command (if any)
    beq.s   @QueueChecked           ; No commands left to process?
    move.b  (a1,d1.w), d2           ; Get mask of flags to leave
    and.b   d2, d0                  ; Remove flags that should be clear
    move.b  OrTable-AndTable(a1,d1.w), d2 ; Get mask of flags to set
    or.b    d2, d0                  ; Insert flags that should be set

    move.b  ($A01FFB), d1           ; Repeat that with 2nd pending command
    beq.s   @QueueChecked
    move.b  (a1,d1.w), d2
    and.b   d2, d0
    move.b  OrTable-AndTable(a1,d1.w), d2
    or.b    d2, d0

@QueueChecked:
    Echo_Z80Release                 ; Let the Z80 go!
    movem.l (sp)+, d1-d2/a1            ; Restore registers
    rts

Echo_SetVolume:
    Echo_Z80Request                 ; We need the Z80 bus
    movem.l d0-d1/a0-a1, -(sp)      ; Save registers
    
    lea     Echo_FMVolTable(pc), a0 ; Determine FM volume
    moveq   #0, d1
    move.b  d0, d1
    lsr.b   #2, d1
    move.b  (a0,d1.w), d1
    
    lea     ($A01FE0), a1           ; Copy new FM volume values
    move.b  d1, (a1)+                 ; FM channel 0
    move.b  d1, (a1)+                 ; FM channel 1
    move.b  d1, (a1)+                 ; FM channel 2
    move.b  d1, (a1)+                 ; FM channel 3
    move.b  d1, (a1)+                 ; FM channel 4
    move.b  d1, (a1)+                 ; FM channel 5
    move.b  d1, (a1)+                 ; FM channel 6
    move.b  d1, (a1)+                 ; FM channel 7
    
    lea     Echo_PSGVolTable(pc),a0 ; Determine PSG volume
    moveq   #0, d1
    move.b  d0, d1
    lsr.b   #2, d1
    move.b  (a0,d1.w), d1
    
                                    ; Copy new PSG values
    move.b  d1, (a1)+                 ; PSG channel 0
    move.b  d1, (a1)+                 ; PSG channel 1
    move.b  d1, (a1)+                 ; PSG channel 2
    move.b  d1, (a1)+                 ; PSG channel 3
    
    cmp.b   #$40, d0                ; Determine whether PCM should be enabled
    shs     d1                        ; (we do an heuristic for enabling PCM
    and.b   #1, d1                    ; based on the volume value)
    move.b  d1, (a1)+
    
    move.b  #1, ($A01FF1)           ; Tell Echo to update the volume levels
    
    movem.l (sp)+, d0-d1/a0-a1      ; Restore registers
    Echo_Z80Release                 ; We're done with the Z80 bus
    rts

Echo_SendCommand:
    movem.l d1/a1-a2, -(sp)         ; Save registers
@Try:
    Echo_Z80Request                 ; We need the Z80 bus

	lea     ($A01FF6), a2           ; Get queue lock
	@Trylock:
	tst.b   (a2)
	beq.s   @Unlocked
	Echo_Z80Release                 ; Let Echo continue
    move.w  #$FF, d1                ; Give it some time
    dbf     d1, *                   ; ...
    Echo_Z80Request                 ; Get Z80 bus back
    bra.s   @Trylock                ; Try again
	@Unlocked:

    lea     ($A01FFF), a1           ; First try the 1st slot
    tst.b   (a1)                    ; Is 1st slot available?
    beq.s   @Ready                    ; If so, move on
    subq.l  #4, a1                  ; Try 2nd slot otherwise

    tst.b   (a1)                    ; Check if 2nd slot is ready
    beq.s   @Ready                  ; Too busy?
    Echo_Z80Release                   ; Let Echo continue
    move.w  #$FF, d1                  ; Give it some time
    dbf     d1, *                       ; ...
    bra.s   @Try                      ; Try again

@Ready:
    move.b  d0, (a1)                ; Write command ID
    Echo_Z80Release                 ; We're done with the Z80 bus

    movem.l (sp)+, d1/a1-a2         ; Restore registers
    rts                             ; End of subroutine

Echo_PlaySFX:
    move.w  d0, -(sp)               ; Save register
    move.b  #$02, d0                ; Command $02 = play SFX
    bsr     Echo_SendCommandAddr    ; Send command to Echo
    move.w  (sp)+, d0               ; Restore register
    
    rts                             ; End of subroutine

Echo_SendCommandAddr:
Echo_SendCommandEx:
    movem.l d0-d1/a1-a2, -(sp)       ; Save registers
@Try:
    Echo_Z80Request                 ; We need the Z80 bus

	lea     ($A01FF6), a2           ; Get queue lock
	@Trylock:
	tst.b   (a2)
	beq.s   @Unlocked
	Echo_Z80Release                 ; Let Echo continue
    move.w  #$FF, d1                ; Give it some time
    dbf     d1, *                   ; ...
    Echo_Z80Request                 ; Get Z80 bus back
    bra.s   @Trylock                ; Try again
	@Unlocked:

    lea     ($A01FFF), a1           ; First try the 1st slot
    tst.b   (a1)                    ; Is 1st slot available?
    beq.s   @Ready                    ; If so, move on
    subq.l  #4, a1                  ; Try 2nd slot otherwise

    tst.b   (a1)                    ; Check if 2nd slot is ready
    beq.s   @Ready                  ; Too busy?
    Echo_Z80Release                   ; Let Echo continue
    move.w  #$FF, d1                  ; Give it some time
    dbf     d1, *                       ; ...
    bra.s   @Try                      ; Try again

@Ready:
    move.b  d0, (a1)                ; Write command ID

    move.l  a0, d0                  ; Easier to manipulate here
    move.b  d0, -2(a1)              ; Store low address byte
    lsr.l   #7, d0                  ; Get high address byte
    lsr.b   #1, d0                    ; We skip one bit
    bset.l  #7, d0                    ; Point into bank window
    move.b  d0, -1(a1)              ; Store high address byte

    lsr.w   #8, d0                  ; Get bank byte
    move.w  d0, d1                    ; Parse 32X bit separately
    lsr.w   #1, d1                    ; Put 32X bit in place
    and.b   #$7F, d0                  ; Filter out unused bit from addresses
    and.b   #$80, d1                  ; Filter out all but 32X bit
    or.b    d1, d0                    ; Put everything together
    move.b  d0, -3(a1)              ; Store bank byte

    Echo_Z80Release                 ; We're done with the Z80 bus

    movem.l (sp)+, d0-d1/a1-a2      ; Restore registers
    rts                             ; End of subroutine

Echo_StopBGM:
    move.w  d0, -(sp)               ; Save register
    move.b  #$05, d0                ; Command $05 = stop BGM
    bsr     Echo_SendCommand        ; Send command to Echo
    move.w  (sp)+, d0               ; Restore register
    
    rts                             ; End of subr

Echo_PlayBGM:
    move.w  d0, -(sp)               ; Save register
    move.b  #$04, d0                ; Command $04 = play BGM
    bsr     Echo_SendCommandAddr    ; Send command to Echo
    move.w  (sp)+, d0               ; Restore register
    
    rts                             ; End of subroutine

Echo_ResumeBGM:
    move.w  d0, -(sp)               ; Save register
    move.b  #$06, d0                ; Command $06 = resume BGM
    bsr     Echo_SendCommand        ; Send command to Echo
    move.w  (sp)+, d0               ; Restore register
    rts                             ; End of 

Echo_PauseBGM:
    move.w  d0, -(sp)               ; Save register
    move.b  #$08, d0                ; Command $08 = pause BGM
    bsr     Echo_SendCommand        ; Send command to Echo
    move.w  (sp)+, d0               ; Restore register
    rts                             ; End 

Echo_DisableSSGEG:

	Echo_Z80Request
	move.b #0x1, ($A01FF7)          ; RAM_SSGEGDisabled
	Echo_Z80Release

    rts                             ; End of subro

Echo_EnableSSGEG:

	Echo_Z80Request
	move.b #0x0, ($A01FF7)          ; RAM_SSGEGDisabled
	Echo_Z80Release

    rts                             ; End of subroutine

Echo_GetSSGEGEnabled:

	Echo_Z80Request
	move.b ($A01FF7), d0            ; RAM_SSGEGDisabled
	Echo_Z80Release

	eor.b #0x1, d0

    rts                             ; End of subroutine

Echo_Init:
    movem.l d0/a0-a1, -(sp)         ; Save registers

    Echo_Z80Reset                   ; May not work without this...
    Echo_Z80Request                 ; We need the Z80 bus

	move.b  #$01, ($A01FF6)         ; Lock command queue

	move.b  #$00, ($A01FFB)         ; Init command queue wait flag

    move.b  #$01, ($A01FFF)         ; Command: load pointer list
	move.b  #$00, ($A01FFB)         ; No other command yet

    move.l  a0, d0                  ; Easier to manipulate here
    move.b  d0, ($A01FFD)           ; Store low address byte
    lsr.l   #7, d0                  ; Get high address byte
    lsr.b   #1, d0                    ; We skip one bit
    bset.l  #7, d0                    ; Point into bank window
    move.b  d0, ($A01FFE)           ; Store high address byte
    lsr.w   #8, d0                  ; Get bank byte
    move.w  d0, d1                    ; Parse 32X bit separately
    lsr.w   #1, d1                    ; Put 32X bit in place
    and.b   #$7F, d0                  ; Filter out unused bit from addresses
    and.b   #$80, d1                  ; Filter out all but 32X bit
    or.b    d1, d0                    ; Put everything together
    move.b  d0, ($A01FFC)           ; Store bank byte

    lea     Z80Program, a0     ; Where Z80 program starts
    lea     ($A00000), a1           ; Where Z80 RAM starts

	IF ECHO_ENCRYPT_Z80
	lea     EchoDecryptKey, a2          ; Decryption key start
	lea     EchoDecryptKeyEnd, a3          ; Decryption key end
	ENDIF

    move.w  #Z80ProgSize-1, d0     ; Size of Z80 program (DBF adjusted)
@LoadLoop:                          ; Go through all the program
	IF ECHO_ENCRYPT_Z80
    move.b  (a0)+, d2
	move.b  (a2)+, d3
	add.b   d2, d3
	move.b  d3, (a1)+
	cmp.l   a2, a3
	bne     @NoWrap
	lea     EchoDecryptKey, a2
	@NoWrap:
	ELSE
	move.b  (a0)+, (a1)+              ; Copy byte into Z80 RAM
	ENDIF
    dbf     d0, @LoadLoop             ; Go for next byte

    moveq   #0, d0                  ; Set default global volumes
    lea     ($A01FE0), a0
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  #1, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, (a0)+
    move.b  d0, ($A01FF1)

    move.b  #$FF, ($A01F00)         ; No direct events to execute

    Echo_Z80Reset                   ; Now reset for real
    Echo_Z80Release                 ; Let the Z80 go!

	@EchoInitWaitLp:                ; Wait for initialisation to complete
	move.w  #$FF, d1                ; Give it some time
    dbf     d1, *                   ; ...
	Echo_Z80Request
	move.b  ($A01FF6), d0           ; Get lock flag
	Echo_Z80Release
	tst.b   d0
	bne     @EchoInitWaitLp

    movem.l (sp)+, d0/a0-a1         ; Restore registers
    rts



