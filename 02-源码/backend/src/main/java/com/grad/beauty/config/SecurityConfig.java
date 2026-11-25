package com.grad.beauty.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.grad.beauty.common.R;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * 安全配置：无状态 JWT。JwtFilter 把 roleCode 直接写成 authority（不加 ROLE_ 前缀），
 * 统一用 hasAuthority / hasAnyAuthority，避免 hasRole 自动加前缀导致全员 403。
 *
 * 角色编码与 sys_role.role_code 一致：admin / operator / auditor / service / analyst / user。
 * 需求第 2 节：前端隐藏按钮不等于授权，所有写接口必须后端复核。
 */
@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtFilter jwtFilter;
    private final ObjectMapper objectMapper;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsSource()))
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/api/auth/login", "/uploads/**", "/error").permitAll()
                .requestMatchers("/api/auth/**").authenticated()
                // 字典、公告、站内消息、个人中心：登录即可
                .requestMatchers("/api/meta/**", "/api/me/**", "/api/portal/**").authenticated()
                .requestMatchers("/api/system/message/**", "/api/system/notice/**").authenticated()
                .requestMatchers(HttpMethod.GET, "/api/dashboard/**", "/api/stat/**").authenticated()
                // 商城与试用展示：登录用户可读（用户端也要看商品）
                .requestMatchers(HttpMethod.GET, "/api/cosmetic-goods/**", "/api/sample-sku/**",
                        "/api/trial-report/**", "/api/convert-rule/current").authenticated()

                // ---------- 系统管理：仅 admin（菜单/角色/用户/字典/日志） ----------
                .requestMatchers("/api/system/user/**", "/api/system/role/**",
                        "/api/system/menu/**", "/api/system/dict/**", "/api/system/log/**")
                        .hasAuthority("admin")

                // ---------- 商品与试用装：品牌运营维护，admin 兜底 ----------
                .requestMatchers(HttpMethod.POST, "/api/cosmetic-goods", "/api/sample-sku",
                        "/api/sample-sku/*/stock").hasAnyAuthority("admin", "operator")
                .requestMatchers(HttpMethod.PUT, "/api/cosmetic-goods/**",
                        "/api/sample-sku/**").hasAnyAuthority("admin", "operator")
                .requestMatchers(HttpMethod.DELETE, "/api/cosmetic-goods/**",
                        "/api/sample-sku/**").hasAnyAuthority("admin", "operator")

                // ---------- 申领：用户提交，运营审核与发放 ----------
                .requestMatchers(HttpMethod.POST, "/api/sample-apply").hasAnyAuthority("admin", "user")
                .requestMatchers(HttpMethod.POST, "/api/sample-apply/*/audit",
                        "/api/sample-apply/*/send", "/api/sample-apply/*/require-profile")
                        .hasAnyAuthority("admin", "operator")

                // ---------- 报告：用户提交，审核员审核 ----------
                .requestMatchers(HttpMethod.POST, "/api/trial-report").hasAnyAuthority("admin", "user")
                .requestMatchers(HttpMethod.POST, "/api/trial-report/*/audit")
                        .hasAnyAuthority("admin", "auditor")

                // ---------- 订单：用户下单/支付，运营退款 ----------
                .requestMatchers(HttpMethod.POST, "/api/makeup-order",
                        "/api/makeup-order/*/pay", "/api/makeup-order/*/cancel")
                        .hasAnyAuthority("admin", "user")
                .requestMatchers(HttpMethod.POST, "/api/makeup-order/*/refund",
                        "/api/makeup-order/*/ship")
                        .hasAnyAuthority("admin", "operator")

                // ---------- 转化：客服跟进、分析师维护规则 ----------
                .requestMatchers(HttpMethod.POST, "/api/convert-track/*/follow",
                        "/api/convert-track/*/correction")
                        .hasAnyAuthority("admin", "service", "analyst")
                .requestMatchers("/api/convert-rule/**")
                        .hasAnyAuthority("admin", "analyst")
                .requestMatchers(HttpMethod.POST, "/api/convert-track/*/score")
                        .hasAnyAuthority("admin", "service", "analyst")

                // ---------- 肤质档案：本人维护 ----------
                .requestMatchers(HttpMethod.POST, "/api/skin-profile", "/api/skin-profile/**")
                        .hasAnyAuthority("admin", "user")
                .anyRequest().authenticated())
            .exceptionHandling(e -> e
                .authenticationEntryPoint((req, res, ex) -> write(res, 4010, "登录状态已失效，请重新登录"))
                .accessDeniedHandler((req, res, ex) -> write(res, 4030, "没有该操作的权限")))
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
            .formLogin(f -> f.disable())
            .httpBasic(b -> b.disable())
            .logout(l -> l.disable());
        return http.build();
    }

    private void write(jakarta.servlet.http.HttpServletResponse res, int code, String msg) throws java.io.IOException {
        res.setStatus(200);
        res.setContentType("application/json;charset=UTF-8");
        res.getWriter().write(objectMapper.writeValueAsString(R.fail(code, msg)));
    }

    private CorsConfigurationSource corsSource() {
        CorsConfiguration c = new CorsConfiguration();
        c.setAllowedOriginPatterns(List.of("http://localhost:*", "http://127.0.0.1:*"));
        c.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        c.setAllowedHeaders(List.of("*"));
        c.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource s = new UrlBasedCorsConfigurationSource();
        s.registerCorsConfiguration("/**", c);
        return s;
    }
}
