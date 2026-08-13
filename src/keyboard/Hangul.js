const INITIALS = {
    "ㄱ": 0, "ㄲ": 1, "ㄴ": 2, "ㄷ": 3, "ㄸ": 4,
    "ㄹ": 5, "ㅁ": 6, "ㅂ": 7, "ㅃ": 8, "ㅅ": 9,
    "ㅆ": 10, "ㅇ": 11, "ㅈ": 12, "ㅉ": 13, "ㅊ": 14,
    "ㅋ": 15, "ㅌ": 16, "ㅍ": 17, "ㅎ": 18
};

const VOWELS = {
    "ㅏ": 0, "ㅐ": 1, "ㅑ": 2, "ㅒ": 3, "ㅓ": 4,
    "ㅔ": 5, "ㅕ": 6, "ㅖ": 7, "ㅗ": 8, "ㅘ": 9,
    "ㅙ": 10, "ㅚ": 11, "ㅛ": 12, "ㅜ": 13, "ㅝ": 14,
    "ㅞ": 15, "ㅟ": 16, "ㅠ": 17, "ㅡ": 18, "ㅢ": 19,
    "ㅣ": 20
};

const FINALS = {
    "ㄱ": 1, "ㄲ": 2, "ㄳ": 3, "ㄴ": 4, "ㄵ": 5,
    "ㄶ": 6, "ㄷ": 7, "ㄹ": 8, "ㄺ": 9, "ㄻ": 10,
    "ㄼ": 11, "ㄽ": 12, "ㄾ": 13, "ㄿ": 14, "ㅀ": 15,
    "ㅁ": 16, "ㅂ": 17, "ㅄ": 18, "ㅅ": 19, "ㅆ": 20,
    "ㅇ": 21, "ㅈ": 22, "ㅊ": 23, "ㅋ": 24, "ㅌ": 25,
    "ㅍ": 26, "ㅎ": 27
};

const FINAL_TO_INITIAL = {
    1: 0, 2: 1, 4: 2, 7: 3, 8: 5, 16: 6, 17: 7,
    19: 9, 20: 10, 21: 11, 22: 12, 23: 14, 24: 15,
    25: 16, 26: 17, 27: 18
};

const COMPOUND_VOWELS = {
    "8:0": 9,
    "8:1": 10,
    "8:20": 11,
    "13:4": 14,
    "13:5": 15,
    "13:20": 16,
    "18:20": 19
};

const COMPOUND_FINALS = {
    "1:1": 2,
    "1:19": 3,
    "4:22": 5,
    "4:27": 6,
    "8:1": 9,
    "8:16": 10,
    "8:17": 11,
    "8:19": 12,
    "8:25": 13,
    "8:26": 14,
    "8:27": 15,
    "17:19": 18,
    "19:19": 20
};

const SPLIT_FINALS = {
    2: [1, 0],
    3: [1, 9],
    5: [4, 12],
    6: [4, 18],
    9: [8, 0],
    10: [8, 6],
    11: [8, 7],
    12: [8, 9],
    13: [8, 16],
    14: [8, 17],
    15: [8, 18],
    18: [17, 9],
    20: [19, 9]
};

const VOWEL_CHARACTERS = [
    "ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ",
    "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"
];

function emptyState() {
    return { kind: "empty" };
}

function isJamo(symbol) {
    return Object.prototype.hasOwnProperty.call(INITIALS, symbol)
        || Object.prototype.hasOwnProperty.call(VOWELS, symbol);
}

function syllable(initial, vowel, finalConsonant) {
    return String.fromCharCode(0xac00 + ((initial * 21) + vowel) * 28 + finalConsonant);
}

function consonantState(symbol) {
    return { kind: "consonant", initial: INITIALS[symbol], text: symbol };
}

function vowelState(vowel) {
    return { kind: "vowel", vowel: vowel, text: VOWEL_CHARACTERS[vowel] };
}

function syllableState(initial, vowel, finalConsonant) {
    return {
        kind: "syllable",
        initial: initial,
        vowel: vowel,
        finalConsonant: finalConsonant,
        text: syllable(initial, vowel, finalConsonant)
    };
}

function result(state, text, replacePrevious) {
    return { state: state, text: text, replacePrevious: replacePrevious };
}

function feedConsonant(state, symbol) {
    const inputFinal = FINALS[symbol];

    if (state.kind === "syllable") {
        if (state.finalConsonant === 0 && inputFinal !== undefined) {
            const next = syllableState(state.initial, state.vowel, inputFinal);
            return result(next, next.text, 1);
        }

        const compound = COMPOUND_FINALS[state.finalConsonant + ":" + inputFinal];
        if (compound !== undefined) {
            const next = syllableState(state.initial, state.vowel, compound);
            return result(next, next.text, 1);
        }
    }

    const next = consonantState(symbol);
    return result(next, symbol, 0);
}

function feedVowel(state, symbol) {
    const inputVowel = VOWELS[symbol];

    if (state.kind === "consonant") {
        const next = syllableState(state.initial, inputVowel, 0);
        return result(next, next.text, 1);
    }

    if (state.kind === "vowel") {
        const compound = COMPOUND_VOWELS[state.vowel + ":" + inputVowel];
        if (compound !== undefined) {
            const next = vowelState(compound);
            return result(next, next.text, 1);
        }
    }

    if (state.kind === "syllable") {
        if (state.finalConsonant === 0) {
            const compound = COMPOUND_VOWELS[state.vowel + ":" + inputVowel];
            if (compound !== undefined) {
                const next = syllableState(state.initial, compound, 0);
                return result(next, next.text, 1);
            }
        } else {
            const split = SPLIT_FINALS[state.finalConsonant];
            const remainingFinal = split ? split[0] : 0;
            const nextInitial = split ? split[1] : FINAL_TO_INITIAL[state.finalConsonant];
            if (nextInitial !== undefined) {
                const committed = syllable(state.initial, state.vowel, remainingFinal);
                const next = syllableState(nextInitial, inputVowel, 0);
                return result(next, committed + next.text, 1);
            }
        }
    }

    const next = vowelState(inputVowel);
    return result(next, symbol, 0);
}

function feed(state, symbol) {
    if (Object.prototype.hasOwnProperty.call(VOWELS, symbol)) {
        return feedVowel(state, symbol);
    }
    if (Object.prototype.hasOwnProperty.call(INITIALS, symbol)) {
        return feedConsonant(state, symbol);
    }
    return result(emptyState(), symbol, 0);
}

if (typeof module !== "undefined") {
    module.exports = { emptyState: emptyState, feed: feed, isJamo: isJamo };
}
