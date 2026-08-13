# web-demo

This is a **committed build artifact**, not source. It's the Flutter web release
build of `mobile-app/`, deployed to Vercel as the public clickable demo.

Vercel has no native Flutter support, so instead of running `flutter build web`
in Vercel's build image, the compiled output is committed here and Vercel just
serves it as a static site (rewrite rule in `vercel.json` handles client-side
routing for `go_router`).

## Regenerating after a mobile-app change

```bash
cd mobile-app
flutter build web --release \
  --dart-define=DEMO_MODE=true \
  --dart-define=API_BASE_URL=https://turf-war-platform.onrender.com/api

rm -rf ../web-demo/{assets,canvaskit,icons,splash,*.js,*.json,*.png,*.html}
cp -R build/web/* ../web-demo/
cd ..
git add web-demo
git commit -m "chore(web-demo): rebuild Flutter web demo"
git push
```

`DEMO_MODE=true` stubs the Stripe payment sheet and skips FCM registration —
neither works in a public web build — and shows a "Demo mode" notice on the
Profile screen. `STRIPE_PUBLISHABLE_KEY` is deliberately omitted so
`PaymentProvider` runs the simulated payment path.
