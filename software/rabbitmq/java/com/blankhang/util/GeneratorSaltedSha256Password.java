package com.blankhang.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;

/**
 * 将给定密码 编码成 rabbitmq 要求的 sha256 加盐
 * <p>
 * <p>
 * https://www.rabbitmq.com/passwords.html#computing-password-hash
 * https://stackoverflow.com/questions/41306350/how-to-generate-password-hash-for-rabbitmq-management-http-api
 *
 * @author blank
 * @date 2020-10-29 上午 10:39
 */
public class GeneratorSaltedSha256Password {

    /**
     * Generates a salted SHA-256 hash of a given password.
     */
    public static String getPasswordHash (String password) {
        byte[] salt = getSalt();
        try {
            byte[] saltedPassword = concatenateByteArray(salt, password.getBytes(StandardCharsets.UTF_8));
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(saltedPassword);

            return Base64.getEncoder().encodeToString(concatenateByteArray(salt, hash));
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Generates a 32 bit random salt.
     */
    private static byte[] getSalt () {
        byte[] ba = new byte[4];
        new SecureRandom().nextBytes(ba);
        return ba;
    }

    /**
     * Concatenates two byte arrays.
     */
    private static byte[] concatenateByteArray (byte[] a, byte[] b) {
        int lenA = a.length;
        int lenB = b.length;
        byte[] c = Arrays.copyOf(a, lenA + lenB);
        System.arraycopy(b, 0, c, lenA, lenB);
        return c;
    }


    public static void main (String args[]) {
        // 修改你的rabbitmq密码
        // please change your rabbitmq password here
        System.out.println(getPasswordHash("blankhang"));
    }
}
