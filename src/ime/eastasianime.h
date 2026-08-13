#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantMap>

#include <composingtext.h>
#include <openwnnenginejajp.h>
#include <romkan.h>

class EastAsianIme : public QObject
{
    Q_OBJECT

public:
    explicit EastAsianIme(QObject *parent = nullptr);
    ~EastAsianIme() override;

    Q_INVOKABLE QVariantMap type(const QString &locale, const QString &symbol);
    Q_INVOKABLE QVariantMap backspace(const QString &locale);
    Q_INVOKABLE QVariantMap selectCandidate(const QString &locale, int index);
    Q_INVOKABLE QVariantMap space(const QString &locale);
    Q_INVOKABLE QVariantMap commit(const QString &locale);
    Q_INVOKABLE QVariantMap reset();
    Q_INVOKABLE bool supports(const QString &locale) const;

private:
    QVariantMap response(
        bool handled,
        int oldLength,
        const QString &replacement = QString()) const;
    void setLocale(const QString &locale);
    void clearState();

    void updateJapanese();
    void updateChinese(int candidateCount);
    QString pinyinCandidateAt(int index) const;
    QString defaultCommitText() const;
    static QString hiraganaToKatakana(const QString &text);

    QString locale_;
    QString preedit_;
    QStringList candidates_;

    ComposingText japaneseText_;
    Romkan romajiConverter_;
    OpenWnnEngineJAJP japaneseEngine_;

    bool pinyinReady_ = false;
    QString pinyinSurface_;
    int pinyinCandidateCount_ = 0;
    int pinyinFixedLength_ = 0;
    int pinyinSpellingCount_ = 0;
};
