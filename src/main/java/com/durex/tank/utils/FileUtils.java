package com.durex.tank.utils;

import java.io.InputStream;
import java.util.Objects;

/**
 * <h1>加载资源文件流</h1>
 *
 * @author liugelong
 * @date 2022/7/24 14:23
 */
public class FileUtils {

    private FileUtils() {
    }

    public static InputStream load(String path) {
        return Objects.requireNonNull(FileUtils.class.getResourceAsStream(path));
    }
}
