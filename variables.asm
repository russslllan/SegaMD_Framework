;===========================================
; Variables
;===========================================
StartRam                equ $FF0000

		rsset 0x00FF0000
vblank_counter          rs.l 1 ;StartRam  
posX                    rs.w 1 ;(vblank_counter+4)
posY                    rs.w 1 ;(posX+2)
gravity                 rs.w 1 ;(posY+2)
speed                   rs.w 1 ;(gravity+2)
floor                   rs.w 1 ;(speed+2)
jump_count              rs.w 1 ;(floor+2)
jump_bool               rs.w 1 ;(jump_count+2)
jump_floor_bool         rs.w 1 ;(jump_bool+2)
jump_lock_bool          rs.w 1 ;(jump_floor_bool+2)
var1                    rs.l 1 ;(jump_lock_bool+2)
vdp_regs			    rs.b $18 ;(var1+4) ; $18
var_hs_scroll           rs.w 1
var_block_posX_left     rs.b 1
var_block_posX_right    rs.b 1

;free_memory             equ (vdp_regs+0x18)

; ************************************
; Audio
; ************************************
Track_Type_COUNT		equ 0x4
audio_clock				rs.l 1
audio_current_track		rs.l 1
audio_queued_tracks		rs.l Track_Type_COUNT
audio_current_sfx		rs.l 1
audio_track_stop_timer	rs.w 1
audio_volume_global		rs.b 1
audio_fader_speed		rs.b 1
audio_playback_locked	rs.b 1
