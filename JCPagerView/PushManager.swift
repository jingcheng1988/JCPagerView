//
//  PushManager.swift
//  IntlPushService
//
//  Created by zhangjc on 2024/3/19.
//

import UserNotifications
import Foundation
import UIKit

let IPS_RequestUrl = "mtop.funtee.lightning.device.register"
let IntlPushGroupName = "group.com.funtee.iphone.appstore"

public class PushManager: NSObject, UIApplicationDelegate {
    // 单例 (使用全局变量而非类变量，是因为不支持类变量，是线程安全的，并且将在第一次调用时进行赋值)
    public static let shared = PushManager()

    // 保证私有化构造方法，不允许外界创建实例
    private override init() {
        super.init()
        // 更新deviceId参数
        shareDataInAppGroup()
    }

    
    // MARK: - 注册通知
    
    public func registAPNSNotifications() {
        // iOS10及以上版本使用
        let unCenter = UNUserNotificationCenter.current();
        unCenter.delegate = self;
        unCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                // 用户授权成功，注册通知
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                // 用户未授权 | 授权失败
                print("Push：用户授权失败")
            }
        }
    }
    
    
    // MARK: - 注册通知回调中调用
    
    public func registerRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        // 注册成功，发送服务端token
        let token = deviceToken.map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
        self.sendDeviceTokenToServer(token);
        print(token)
    }
    
    public func registerForRemoteNotificationsWithError(_ error: Error) {
        // 注册失败
        print(error);
    }
    
    // 上报token
    private func sendDeviceTokenToServer(_ token: String) {

    }

    
    // MARK: - 清空通知
    // App被唤醒后清空通知栏消息
    public func clearNotificationsAndBadgeNumber() {
        setBadgeNumber(-1)
        setBadgeNumber(0)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // 修改气泡数
    public func setBadgeNumber(_ number: Int) {
        // 清理通知数量
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(number)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = number;
        }
    }
    
    
    // MARK: - 处理通知
    
    func handleRemoteNotification(_ userInfo: [String: Any]) {
        // 清除通知栏 & 通知角标
        clearNotificationsAndBadgeNumber()
        // 跳转路由
    }
    
    func reportNotification(_ userInfo: [String: Any]) {

    }
            
    // MARK: - AppGroup参数
    private func shareDataInAppGroup() {
        if let shareDefault = UserDefaults(suiteName: IntlPushGroupName) {
            // secretKey
            shareDefault.setValue("", forKey: "secretKey")
            // appKey
            shareDefault.setValue("", forKey: "appKey")
            // environment
            shareDefault.setValue("", forKey: "environmentType")
        }
    }
}


extension PushManager: UNUserNotificationCenterDelegate {
    
    // 前台收到消息
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 处理用户点击通知的操作
        if let userInfo = notification.request.content.userInfo as? [String: Any] {
            reportNotification(userInfo)
        }
        // 处理前台收到的通知
        completionHandler([.alert, .sound, .badge])
    }
    
    // 通知栏消息唤端
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 处理用户点击通知的操作
        if let userInfo = response.notification.request.content.userInfo as? [String: Any] {
            reportNotification(userInfo)
            handleRemoteNotification(userInfo)
        }
        // 完成后台收到消息通知
        completionHandler()
    }
    
}

