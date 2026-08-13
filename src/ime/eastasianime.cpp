#include "eastasianime.h"

#include <QByteArray>
#include <QDir>
#include <QFileInfo>
#include <QSet>

#include <dictdef.h>
#include <pinyinime.h>
#include <strsegment.h>
#include <wnnword.h>

using namespace ime_pinyin;

namespace {
constexpr int MaxCandidates = 30;

bool isEastAsianLocale(const QString &locale)
{
    return locale == QStringLiteral("ja_JP") || locale == QStringLiteral("zh_CN");
}
}

EastAsianIme::EastAsianIme(QObject *parent)
    : QObject(parent)
{
    japaneseEngine_.setDictionary(OpenWnnEngineJAJP::DIC_LANG_JP);

    const QString dictionary = qEnvironmentVariable(
        "RM_EASTASIAN_PINYIN_DICTIONARY",
        "/home/root/xovi/exthome/qt-resource-rebuilder/east-asian/dict_pinyin.dat");
    if (QFileInfo::exists(dictionary)) {
        const QString userDictionary = qEnvironmentVariable(
            "RM_EASTASIAN_PINYIN_USER_DICTIONARY",
            "/home/root/.config/remarkable-east-asian-ime/pinyin-user.dat");
        QDir().mkpath(QFileInfo(userDictionary).absolutePath());
        pinyinReady_ = im_open_decoder(
            dictionary.toUtf8().constData(),
            userDictionary.toUtf8().constData());
        if (pinyinReady_) {
            im_set_max_lens(32, 32);
        }
    }
}

EastAsianIme::~EastAsianIme()
{
    if (pinyinReady_) {
        im_close_decoder();
    }
}

bool EastAsianIme::supports(const QString &locale) const
{
    return locale == QStringLiteral("ja_JP")
        || (locale == QStringLiteral("zh_CN") && pinyinReady_);
}

QVariantMap EastAsianIme::type(const QString &locale, const QString &symbol)
{
    setLocale(locale);
    const int oldLength = preedit_.size();
    if (!supports(locale) || symbol.size() != 1) {
        return response(false, oldLength);
    }

    const QChar character = symbol.at(0).toLower();
    if (!(character >= u'a' && character <= u'z') && character != u'\'') {
        return response(false, oldLength);
    }

    if (locale == QStringLiteral("ja_JP")) {
        japaneseText_.insertStrSegment(
            ComposingText::LAYER0,
            ComposingText::LAYER1,
            StrSegment(character));
        romajiConverter_.convert(japaneseText_);
        updateJapanese();
    } else {
        if (character == u'\'' && (pinyinSurface_.isEmpty() || pinyinSurface_.endsWith(character))) {
            return response(true, oldLength, preedit_);
        }
        pinyinSurface_.append(character);
        im_reset_search();
        updateChinese(int(im_search(
            pinyinSurface_.toLatin1().constData(),
            size_t(pinyinSurface_.size()))));
    }

    return response(true, oldLength, preedit_);
}

QVariantMap EastAsianIme::backspace(const QString &locale)
{
    setLocale(locale);
    const int oldLength = preedit_.size();
    if (!supports(locale) || oldLength == 0) {
        return response(false, oldLength);
    }

    if (locale == QStringLiteral("ja_JP")) {
        japaneseText_.deleteAt(ComposingText::LAYER0, false);
        updateJapanese();
    } else {
        if (!pinyinSurface_.isEmpty()) {
            pinyinSurface_.chop(1);
        }
        im_reset_search();
        if (pinyinSurface_.isEmpty()) {
            preedit_.clear();
            candidates_.clear();
            pinyinCandidateCount_ = 0;
            pinyinFixedLength_ = 0;
            pinyinSpellingCount_ = 0;
        } else {
            updateChinese(int(im_search(
                pinyinSurface_.toLatin1().constData(),
                size_t(pinyinSurface_.size()))));
        }
    }

    return response(true, oldLength, preedit_);
}

QVariantMap EastAsianIme::selectCandidate(const QString &locale, int index)
{
    setLocale(locale);
    const int oldLength = preedit_.size();
    if (!supports(locale) || index < 0 || index >= candidates_.size()) {
        return response(false, oldLength);
    }

    if (locale == QStringLiteral("ja_JP")) {
        const QString selected = candidates_.at(index);
        clearState();
        locale_ = locale;
        return response(true, oldLength, selected);
    }

    if (pinyinCandidateCount_ <= 1) {
        const QString selected = candidates_.at(index);
        clearState();
        locale_ = locale;
        return response(true, oldLength, selected);
    }

    const int nextCount = int(im_choose(size_t(index)));
    updateChinese(nextCount);
    if (pinyinSpellingCount_ > 0 && pinyinFixedLength_ >= pinyinSpellingCount_) {
        const QString selected = preedit_;
        clearState();
        locale_ = locale;
        return response(true, oldLength, selected);
    }
    return response(true, oldLength, preedit_);
}

QVariantMap EastAsianIme::space(const QString &locale)
{
    setLocale(locale);
    const int oldLength = preedit_.size();
    if (!supports(locale) || oldLength == 0) {
        return response(false, oldLength);
    }
    if (!candidates_.isEmpty()) {
        return selectCandidate(locale, 0);
    }

    const QString selected = preedit_;
    clearState();
    locale_ = locale;
    return response(true, oldLength, selected);
}

QVariantMap EastAsianIme::commit(const QString &locale)
{
    setLocale(locale);
    const int oldLength = preedit_.size();
    if (!supports(locale) || oldLength == 0) {
        return response(false, oldLength);
    }

    const QString selected = defaultCommitText();
    clearState();
    locale_ = locale;
    return response(true, oldLength, selected);
}

QVariantMap EastAsianIme::reset()
{
    const int oldLength = preedit_.size();
    clearState();
    return response(oldLength > 0, oldLength);
}

QVariantMap EastAsianIme::response(
    bool handled,
    int oldLength,
    const QString &replacement) const
{
    return {
        {QStringLiteral("handled"), handled},
        {QStringLiteral("oldLength"), oldLength},
        {QStringLiteral("replacement"), replacement},
        {QStringLiteral("preedit"), preedit_},
        {QStringLiteral("active"), !preedit_.isEmpty()},
        {QStringLiteral("candidates"), candidates_},
    };
}

void EastAsianIme::setLocale(const QString &locale)
{
    if (locale_ == locale) {
        return;
    }
    clearState();
    locale_ = locale;
}

void EastAsianIme::clearState()
{
    preedit_.clear();
    candidates_.clear();
    japaneseText_.clear();
    japaneseEngine_.breakSequence();

    pinyinSurface_.clear();
    pinyinCandidateCount_ = 0;
    pinyinFixedLength_ = 0;
    pinyinSpellingCount_ = 0;
    if (pinyinReady_) {
        im_reset_search();
    }
}

void EastAsianIme::updateJapanese()
{
    preedit_ = japaneseText_.toString(ComposingText::LAYER1);
    candidates_.clear();
    if (preedit_.isEmpty()) {
        return;
    }

    QSet<QString> seen;
    if (japaneseEngine_.predict(japaneseText_, 0, -1) >= 0) {
        while (candidates_.size() < MaxCandidates) {
            const QSharedPointer<WnnWord> word = japaneseEngine_.getNextCandidate();
            if (word.isNull()) {
                break;
            }
            if (!word->candidate.isEmpty() && !seen.contains(word->candidate)) {
                seen.insert(word->candidate);
                candidates_.append(word->candidate);
            }
        }
    }

    const QString katakana = hiraganaToKatakana(preedit_);
    for (const QString &fallback : {preedit_, katakana}) {
        if (!fallback.isEmpty() && !seen.contains(fallback)) {
            seen.insert(fallback);
            candidates_.append(fallback);
        }
    }
}

void EastAsianIme::updateChinese(int candidateCount)
{
    pinyinCandidateCount_ = candidateCount;
    candidates_.clear();

    size_t decodedLength = 0;
    const char *spelling = im_get_sps_str(&decodedLength);
    pinyinSurface_ = QString::fromLatin1(spelling);

    const uint16 *starts = nullptr;
    pinyinSpellingCount_ = int(im_get_spl_start_pos(starts));
    pinyinFixedLength_ = int(im_get_fixed_len());

    const QString fullSentence = pinyinCandidateAt(0);
    const int fixedCharacters = qMin(pinyinFixedLength_, fullSentence.size());
    const QString fixedText = fullSentence.left(fixedCharacters);
    const int remainingStart = starts && pinyinFixedLength_ <= pinyinSpellingCount_
        ? int(starts[pinyinFixedLength_])
        : 0;
    preedit_ = fixedText + pinyinSurface_.mid(remainingStart).toLower();

    const int count = qMin(candidateCount, MaxCandidates);
    for (int index = 0; index < count; ++index) {
        QString candidate = pinyinCandidateAt(index);
        if (index == 0 && !fixedText.isEmpty() && candidate.startsWith(fixedText)) {
            candidate.remove(0, fixedText.size());
        }
        if (!candidate.isEmpty() && !candidates_.contains(candidate)) {
            candidates_.append(candidate);
        }
    }

    if (candidates_.isEmpty() && !preedit_.isEmpty()) {
        candidates_.append(preedit_);
    }
}

QString EastAsianIme::pinyinCandidateAt(int index) const
{
    if (!pinyinReady_ || index < 0) {
        return QString();
    }
    QList<QChar> buffer(kMaxSearchSteps + 1, u'\0');
    if (!im_get_candidate(size_t(index), reinterpret_cast<char16 *>(buffer.data()), kMaxSearchSteps)) {
        return QString();
    }
    return QString(buffer.constData());
}

QString EastAsianIme::defaultCommitText() const
{
    if (locale_ == QStringLiteral("ja_JP")) {
        return preedit_;
    }
    if (locale_ == QStringLiteral("zh_CN") && pinyinCandidateCount_ > 0) {
        const QString sentence = pinyinCandidateAt(0);
        if (!sentence.isEmpty()) {
            return sentence;
        }
    }
    if (!candidates_.isEmpty()) {
        return candidates_.first();
    }
    return preedit_;
}

QString EastAsianIme::hiraganaToKatakana(const QString &text)
{
    QString result = text;
    for (QChar &character : result) {
        const ushort code = character.unicode();
        if (code >= 0x3041 && code <= 0x3096) {
            character = QChar(code + 0x60);
        }
    }
    return result;
}
