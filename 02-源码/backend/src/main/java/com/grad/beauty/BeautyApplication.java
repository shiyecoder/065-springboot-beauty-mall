package com.grad.beauty;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * 美妆护肤商城与试用装派发系统 启动类。
 * JDK 17 + Spring Boot 3.3.5，定时任务用于结案超期申领与每日转化重算。
 */
@EnableScheduling
@MapperScan("com.grad.beauty.mapper")
@SpringBootApplication
public class BeautyApplication {
    public static void main(String[] args) {
        SpringApplication.run(BeautyApplication.class, args);
    }
}
