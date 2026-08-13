#include "eastasianime.h"

#include <QCoreApplication>
#include <QDebug>

namespace {
QVariantMap type(EastAsianIme &ime, const QString &locale, const QString &text)
{
    QVariantMap result;
    for (const QChar character : text) {
        result = ime.type(locale, character);
    }
    return result;
}

bool containsCandidate(const QVariantMap &result, const QString &candidate)
{
    return result.value(QStringLiteral("candidates")).toStringList().contains(candidate);
}
}

int main(int argc, char **argv)
{
    QCoreApplication application(argc, argv);
    EastAsianIme ime;

    QVariantMap result = type(ime, QStringLiteral("ja_JP"), QStringLiteral("nihongo"));
    if (result.value(QStringLiteral("preedit")).toString() != QStringLiteral("にほんご")
        || !containsCandidate(result, QStringLiteral("日本語"))) {
        qCritical() << "Japanese conversion failed" << result;
        return 1;
    }
    ime.reset();
    result = type(ime, QStringLiteral("ja_JP"), QStringLiteral("hiragana"));
    if (result.value(QStringLiteral("preedit")).toString() != QStringLiteral("ひらがな")) {
        qCritical() << "Hiragana composition failed" << result;
        return 2;
    }

    ime.reset();
    result = type(ime, QStringLiteral("ja_JP"), QStringLiteral("nihongo"));
    QVariantMap hiraganaCommit = ime.commit(QStringLiteral("ja_JP"));
    if (hiraganaCommit.value(QStringLiteral("replacement")).toString()
        != QStringLiteral("にほんご")) {
        qCritical() << "Hiragana commit failed" << hiraganaCommit;
        return 3;
    }

    result = type(ime, QStringLiteral("ja_JP"), QStringLiteral("nihongo"));
    result = ime.selectCandidate(QStringLiteral("ja_JP"),
        result.value(QStringLiteral("candidates")).toStringList().indexOf(QStringLiteral("日本語")));
    if (result.value(QStringLiteral("replacement")).toString() != QStringLiteral("日本語")) {
        qCritical() << "Japanese selection failed" << result;
        return 4;
    }

    result = type(ime, QStringLiteral("ja_JP"), QStringLiteral("katakana"));
    if (!containsCandidate(result, QStringLiteral("カタカナ"))) {
        qCritical() << "Katakana conversion failed" << result;
        return 5;
    }

    ime.reset();
    result = type(ime, QStringLiteral("ja_JP"), QStringLiteral("kyo"));
    if (result.value(QStringLiteral("preedit")).toString() != QStringLiteral("きょ")) {
        qCritical() << "Small kana conversion failed" << result;
        return 6;
    }
    result = ime.backspace(QStringLiteral("ja_JP"));
    if (result.value(QStringLiteral("preedit")).toString() != QStringLiteral("き")) {
        qCritical() << "Japanese raw backspace failed" << result;
        return 7;
    }

    ime.reset();
    result = type(ime, QStringLiteral("zh_CN"), QStringLiteral("zhongguo"));
    if (!containsCandidate(result, QStringLiteral("中国"))) {
        qCritical() << "Chinese conversion failed" << result;
        return 8;
    }
    result = ime.commit(QStringLiteral("zh_CN"));
    if (result.value(QStringLiteral("replacement")).toString() != QStringLiteral("中国")) {
        qCritical() << "Chinese commit failed" << result;
        return 9;
    }

    result = type(ime, QStringLiteral("zh_CN"), QStringLiteral("nihao"));
    if (!containsCandidate(result, QStringLiteral("你好"))) {
        qCritical() << "Chinese phrase conversion failed" << result;
        return 10;
    }
    result = ime.backspace(QStringLiteral("zh_CN"));
    if (!result.value(QStringLiteral("active")).toBool()
        || result.value(QStringLiteral("preedit")).toString() != QStringLiteral("niha")) {
        qCritical() << "Chinese backspace failed" << result;
        return 11;
    }

    qInfo() << "East Asian IME tests passed";
    return 0;
}
