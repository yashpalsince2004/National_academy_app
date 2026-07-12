export function getDifficultyWeightage(level: string): string {
  switch (level.toLowerCase()) {
    case "basic":
      return "- Easy questions: 70%, Medium questions: 25%, Hard questions: 5%";
    case "high":
    case "advanced":
      return "- Easy questions: 10%, Medium questions: 35%, Hard questions: 55%";
    case "medium":
    default:
      return "- Easy questions: 30%, Medium questions: 50%, Hard questions: 20%";
  }
}
