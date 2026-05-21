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

export { toTitleCase };
