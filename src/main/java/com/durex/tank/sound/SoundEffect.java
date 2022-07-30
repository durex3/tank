package com.durex.tank.sound;


import javafx.scene.media.AudioClip;

import java.util.Objects;

/**
 * <h1>音效类</h1>
 *
 * @author liugelong
 * @date 2022/7/30 12:15
 */
public class SoundEffect {

    private SoundEffect() {
    }

    public static void play(String src) {
        AudioClip audioClip = new AudioClip(Objects.requireNonNull(SoundEffect.class.getResource(src)).toString());
        audioClip.play();
    }
}
