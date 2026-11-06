# طمّني (Tammene)

نظام لسلامة الطلاب في النقل المدرسي: السائق يسجّل صعود ونزول كل طالب بضغطة، وولي الأمر يستقبل
إشعاراً لحظياً، ولا تنتهي الرحلة وفيها طالب لم يُسجَّل نزوله.

> ⚠️ **نسخة قيد التطوير.** .

🌐 **الموقع التعريفي:** [about.tammene.com](https://about.tammene.com)

## التشغيل محلياً

المتطلبات: Node.js 22 أو أحدث فقط. **لا حاجة لـ Docker ولا لأي حساب خارجي.**

```bash
npm i -g pnpm
pnpm install
pnpm run setup
pnpm dev
```

| الخدمة        | العنوان                    |
| ------------- | -------------------------- |
| التطبيق       | http://localhost:5173      |
| توثيق الـ API | http://localhost:3000/docs |
| بريد التطوير  | http://localhost:8025      |

```bash
pnpm test        # كل الاختبارات (مع PostgreSQL حقيقي)
pnpm lint        # ESLint + فحص الأسرار
pnpm typecheck
```

## الوثائق

- [الخطة الكاملة](docs/PLAN.md)
- [القرارات](docs/DECISIONS.md)
- [سجل التغييرات](docs/CHANGELOG.md)
- [تعليمات للمساعد البرمجي](CLAUDE.md)
