const assert = require("node:assert/strict");
const Hangul = require("../src/keyboard/Hangul.js");

function typeJamo(jamo) {
    let state = Hangul.emptyState();
    let text = "";
    for (const symbol of jamo) {
        text += symbol;
        const edit = Hangul.feed(state, symbol);
        state = edit.state;
        if (edit.replacePrevious !== 0 || edit.text !== symbol) {
            const deleteCount = edit.replacePrevious + 1;
            text = text.slice(0, -deleteCount) + edit.text;
        }
    }
    return text;
}

const cases = [
    ["ㅎㅏㄴㄱㅡㄹ", "한글"],
    ["ㅇㅏㄴㄴㅕㅇㅎㅏㅅㅔㅇㅛ", "안녕하세요"],
    ["ㄱㅗㅏ", "과"],
    ["ㅇㅜㅓㄴ", "원"],
    ["ㅇㅡㅣ", "의"],
    ["ㄷㅏㄹㄱㅏ", "달가"],
    ["ㅂㅏㄱㄱ", "밖"],
    ["ㅂㅏㄱㄱㅏ", "박가"],
    ["ㄱㅏㅂㅅ", "값"],
    ["ㄱㅏㅂㅅㅏ", "갑사"],
    ["ㅃㅏㄹㄹㅣ", "빨리"],
    ["ㅗㅏ", "ㅘ"],
    ["ㅏㅓ", "ㅏㅓ"]
];

for (const [input, expected] of cases) {
    assert.equal(typeJamo(input), expected, input);
}

console.log(`Hangul composition: ${cases.length} cases passed`);
