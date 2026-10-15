import path from "node:path";

const prepositions = new Set([
  "to",
  "in",
  "with",
  "on",
  "at",
  "by",
  "for",
  "from",
  "up",
  "down",
  "over",
  "under",
]);
const isPreposition = (word: string) => prepositions.has(word.toLowerCase());

const toTitleCase = (str: string) => {
  const yearRangeMatch = str.match(/(\d{4}-\d{4})/);
  const yearRange = yearRangeMatch ? yearRangeMatch[0] : "";
  return (
    str
      .replace(yearRange, "")
      .split(/[-_]+/)
      .map((word, index) =>
        isPreposition(word) && index !== 0
          ? word.toLowerCase()
          : word.charAt(0).toUpperCase() + word.slice(1).toLowerCase(),
      )
      .join(" ") + yearRange
  );
};

const faviconPath = (target: string, root: string) => {
  const relative = path.relative(path.dirname(target), path.join(root, "favicon.svg"));
  return relative.split(path.sep).map(encodeURIComponent).join("/");
};

const escapeHtml = (text: string) =>
  text.replace(/[&<>"']/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  })[char]!);

export { toTitleCase, faviconPath, escapeHtml };
