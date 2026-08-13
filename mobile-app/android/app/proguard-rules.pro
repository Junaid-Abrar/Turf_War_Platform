# flutter_stripe bundles an optional Android push-provisioning feature (adding
# cards to Google Pay via a card-issuer's app) that this app doesn't use. R8
# still trips over the missing classes it references because the underlying
# Play Services artifact isn't declared as a dependency here. Keep rules,
# rather than a runtime dependency, since the feature is genuinely unused.
# https://github.com/flutter-stripe/flutter_stripe/issues/1155
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }
