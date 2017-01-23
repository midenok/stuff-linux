#!/bin/sh
name="AlpsPS/2 ALPS DualPoint TouchPad"
xinput set-int-prop "$name" "Synaptics Two-Finger Scrolling" 8 1 1
xinput set-int-prop "$name" "Synaptics Two-Finger Pressure" 32 1
xinput set-int-prop "$name" "Synaptics Two-Finger Width" 32 8
xinput set-int-prop "$name" "Synaptics Jumpy Cursor Threshold" 32 200
xinput set-int-prop "$name" "Synaptics Palm Detection" 8 1
xinput set-int-prop "$name" "Synaptics Palm Dimension" 32 15 250
xinput set-int-prop "$name" "Synaptics Locked Drags" 8 1
xinput set-int-prop "$name" "Synaptics Tap Action" 8 2 3 0 0 1 3 2
xinput set-int-prop "$name" "Circular Scrolling" 8 1
xinput set-int-prop "$name" "Synaptics Edge Scrolling" 8 1 1 1
xinput set-int-prop "$name" "Synaptics Edge Motion Pressure" 32 70 100
xinput set-int-prop "$name" "Synaptics Edge Motion Speed" 32 30 500 



