function parseJson(string) {
    try {
        return JSON.parse(string);
    } catch (error) {
        return null;
    }
}

function renderJson(json) {
    return JSON.stringify(json, null, 2);
}
