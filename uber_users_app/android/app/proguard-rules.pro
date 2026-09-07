# R8 / ProGuard rules for the users app (picked up automatically by Flutter's
# Gradle plugin from android/app/proguard-rules.pro in release builds).

# flutter_stripe (stripe_android) references Stripe's optional push-provisioning
# classes that are not on the classpath. Without these rules the release build
# fails with "Missing classes detected while running R8".
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-dontwarn com.reactnativestripesdk.pushprovisioning.**
