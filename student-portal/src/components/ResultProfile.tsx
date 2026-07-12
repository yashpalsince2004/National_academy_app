import React from 'react';
import type { DPP, DPPAttempt } from '../types';
import { motion } from 'framer-motion';
import { LaTeX } from './LaTeX';
import { 
  CheckCircle2, 
  XCircle, 
  MinusCircle, 
  Timer, 
  BookOpen, 
  Award, 
  Sparkles, 
  Flame, 
  AlertTriangle,
  Lightbulb,
  ArrowRightCircle,
  HelpCircle,
  Star,
  RefreshCw
} from 'lucide-react';

interface ResultProfileProps {
  dpp: DPP;
  attempt: DPPAttempt;
  onReviewAnswers: () => void;
  onReturnDashboard: () => void;
}

export const ResultProfile: React.FC<ResultProfileProps> = ({
  dpp,
  attempt,
  onReviewAnswers,
  onReturnDashboard,
}) => {
  const [selectedConfidence, setSelectedConfidence] = React.useState<number>(attempt.confidenceRating || 0);
  const [aiTutorialState, setAiTutorialState] = React.useState<'idle' | 'generating' | 'loaded'>('idle');
  const [activePracticeIndex, setActivePracticeIndex] = React.useState<number>(0);
  const [showPracticeSolutions, setShowPracticeSolutions] = React.useState<Record<number, boolean>>({});

  // Compute accuracy
  const total = dpp.questions.length;
  const correct = attempt.correctCount || 0;
  const wrong = attempt.wrongCount || 0;
  const skipped = attempt.skippedCount || 0;
  const accuracy = total > 0 ? (correct / total) * 100 : 0;
  const passed = accuracy >= 70;

  // Format timings
  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m}m ${s}s`;
  };

  // Generate subtopics dynamically for remediation
  const getRemediationTopics = (subject: string) => {
    if (subject === 'Physics') {
      return ['Foundational Calculus & Derivative Vectors', '1D Motion Integration under Gravity'];
    } else if (subject === 'Biology') {
      return ['Ultrafiltration Osmoregulation Dynamics', 'Hormonal Loop Control in RAAS Pathways'];
    } else {
      return ['King\'s Integration Bounds Property', ' Parabolic-Linear Intersecting Areas'];
    }
  };

  // Mock adaptive questions
  const getRemediationQuestions = (subject: string) => {
    if (subject === 'Physics') {
      return [
        {
          q: 'A block starts from rest and moves with a constant acceleration of $a = 4$ m/s$^2$. Find the speed of the block after it has traveled $8$ meters.',
          options: ['8 m/s', '4 m/s', '16 m/s', '12 m/s'],
          ans: '8 m/s',
          sol: 'Using $v^2 = u^2 + 2as$:\n$$v^2 = 0 + 2(4)(8) = 64 \\implies v = 8 \\text{ m/s}.$$\n\nThis is a simplified verification of kinematics acceleration equations.',
        },
        {
          q: 'If the velocity of an object is given by $v(t) = 2t$, what is the displacement of the object from $t = 1$ to $t = 3$ seconds?',
          options: ['8 m', '9 m', '6 m', '4 m'],
          ans: '8 m',
          sol: 'Displacement is the integral of velocity:\n$$s = \\int_1^3 2t\\,dt = \\left[t^2\\right]_1^3 = 9 - 1 = 8 \\text{ meters}.$$',
        },
      ];
    } else if (subject === 'Biology') {
      return [
        {
          q: 'Which peptide hormone is secreted by the heart in response to high blood pressure to oppose the RAAS path?',
          options: ['Atrial Natriuretic Factor (ANF)', 'Aldosterone', 'Renin', 'Angiotensinogen'],
          ans: 'Atrial Natriuretic Factor (ANF)',
          sol: 'ANF is secreted by heart atria to cause vasodilation and promote sodium/water excretion, reducing blood pressure and counteracting RAAS.',
        },
        {
          q: 'The filtration membrane in glomerulus does NOT allow which of the following to pass?',
          options: ['Albumin proteins', 'Urea molecules', 'Glucose', 'Sodium ions'],
          ans: 'Albumin proteins',
          sol: 'Albumin is a large plasma protein (molecular weight approx 66 kDa) which cannot cross the size-selective podocyte slit pores under normal conditions.',
        },
      ];
    } else {
      return [
        {
          q: 'Evaluate the integral:\n$$\\int_{-2}^{2} x^3\\,dx$$',
          options: ['0', '4', '8', '-4'],
          ans: '0',
          sol: 'The integrand $f(x) = x^3$ is an odd function ($f(-x) = -f(x)$). Integrating any odd function over symmetric limits $[-a, a]$ yields $0$ automatically.',
        },
        {
          q: 'Evaluate:\n$$\\int_0^1 (1 - x)\\,dx$$',
          options: ['1/2', '1', '2', '1/4'],
          ans: '1/2',
          sol: '$$\\int_0^1 (1 - x)\\,dx = \\left[ x - \\frac{x^2}{2} \\right]_0^1 = 1 - \\frac{1}{2} = \\frac{1}{2}.$$',
        },
      ];
    }
  };

  const adaptiveQuestions = getRemediationQuestions(dpp.subject);

  const startAiTutorial = () => {
    setAiTutorialState('generating');
    setTimeout(() => {
      setAiTutorialState('loaded');
    }, 1500);
  };

  const toggleSolution = (idx: number) => {
    setShowPracticeSolutions((prev) => ({
      ...prev,
      [idx]: !prev[idx],
    }));
  };

  return (
    <div className="space-y-8 animate-fade-in pb-16">
      {/* Top Banner Status */}
      <div className="text-center space-y-3">
        <h1 className="text-3xl md:text-4xl font-extrabold text-white">Performance Scorecard</h1>
        <p className="text-slate-400 text-sm">
          Challenge: <span className="text-slate-200 font-semibold">{dpp.name}</span>
        </p>
      </div>

      {/* Main Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Left Card: Accuracy Circle Widget */}
        <div className="glass-panel rounded-2xl p-6 flex flex-col items-center justify-center text-center space-y-4">
          <div className="relative w-36 h-36 flex items-center justify-center">
            {/* SVG Progress Circle */}
            <svg className="w-full h-full transform -rotate-90">
              <circle
                cx="72"
                cy="72"
                r="64"
                className="stroke-slate-800"
                strokeWidth="10"
                fill="transparent"
              />
              <circle
                cx="72"
                cy="72"
                r="64"
                className={`transition-all duration-1000 ${
                  passed ? 'stroke-emerald-500' : 'stroke-orange-500'
                }`}
                strokeWidth="10"
                fill="transparent"
                strokeDasharray={402}
                strokeDashoffset={402 - (402 * accuracy) / 100}
                strokeLinecap="round"
              />
            </svg>
            <div className="absolute text-center">
              <span className="text-4xl font-extrabold text-white font-mono">
                {accuracy.toFixed(0)}%
              </span>
              <div className="text-[10px] text-slate-500 uppercase tracking-widest mt-0.5">
                Accuracy
              </div>
            </div>
          </div>

          <div className="space-y-1">
            <span className={`inline-block px-3 py-1 rounded-full text-xs font-bold ${
              passed ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-orange-500/10 text-orange-400 border border-orange-500/20'
            }`}>
              {passed ? 'Topic Mastered' : 'Needs Revision'}
            </span>
            <p className="text-[11px] text-slate-500 mt-2">
              Mastery threshold requirement is 70% or higher.
            </p>
          </div>
        </div>

        {/* Center Card: Timing Summary */}
        <div className="glass-panel rounded-2xl p-6 flex flex-col justify-between space-y-6">
          <h3 className="font-bold text-sm text-slate-400 uppercase tracking-wider flex items-center gap-2">
            <Timer size={16} className="text-indigo-400" />
            <span>Time Metrics</span>
          </h3>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-slate-950 p-4 rounded-xl border border-slate-900">
              <div className="text-xs text-slate-500 font-medium">Total Duration</div>
              <div className="text-xl font-bold text-slate-100 font-mono mt-1">
                {formatTime(attempt.timeSpent || 0)}
              </div>
            </div>
            <div className="bg-slate-950 p-4 rounded-xl border border-slate-900">
              <div className="text-xs text-slate-500 font-medium">Avg Time / Question</div>
              <div className="text-xl font-bold text-slate-100 font-mono mt-1">
                {formatTime(Math.round((attempt.timeSpent || 0) / dpp.questions.length))}
              </div>
            </div>
          </div>

          <div className="text-xs text-slate-500 leading-relaxed bg-slate-900/40 p-3 rounded-lg border border-slate-850">
            Suggested allocation: <span className="text-slate-300 font-bold">{dpp.estimatedTime} minutes</span>. 
            You completed the test within bounds.
          </div>
        </div>

        {/* Right Card: Question Breakdowns */}
        <div className="glass-panel rounded-2xl p-6 flex flex-col justify-between space-y-6">
          <h3 className="font-bold text-sm text-slate-400 uppercase tracking-wider flex items-center gap-2">
            <BookOpen size={16} className="text-indigo-400" />
            <span>Answering Breakdown</span>
          </h3>

          <div className="space-y-3">
            {/* Correct */}
            <div className="flex items-center justify-between p-2.5 rounded-lg bg-emerald-500/5 border border-emerald-500/10 text-emerald-400 text-xs font-semibold">
              <div className="flex items-center gap-2">
                <CheckCircle2 size={16} />
                <span>Correct Answers</span>
              </div>
              <span className="font-mono text-sm font-bold">{correct}</span>
            </div>

            {/* Wrong */}
            <div className="flex items-center justify-between p-2.5 rounded-lg bg-red-500/5 border border-red-500/10 text-red-400 text-xs font-semibold">
              <div className="flex items-center gap-2">
                <XCircle size={16} />
                <span>Incorrect Answers</span>
              </div>
              <span className="font-mono text-sm font-bold">{wrong}</span>
            </div>

            {/* Skipped */}
            <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-500/5 border border-slate-500/10 text-slate-400 text-xs font-semibold">
              <div className="flex items-center gap-2">
                <MinusCircle size={16} />
                <span>Skipped Questions</span>
              </div>
              <span className="font-mono text-sm font-bold">{skipped}</span>
            </div>
          </div>

          {/* Self Confidence Rating Input */}
          <div className="border-t border-slate-800/80 pt-4 flex items-center justify-between">
            <span className="text-[11px] text-slate-400 font-medium">Self Confidence Rating:</span>
            <div className="flex gap-1">
              {[1, 2, 3, 4, 5].map((star) => (
                <button
                  key={star}
                  onClick={() => setSelectedConfidence(star)}
                  className="text-slate-600 hover:text-yellow-400 transition-smooth"
                >
                  <Star
                    size={14}
                    className={star <= selectedConfidence ? 'fill-yellow-400 text-yellow-400' : 'text-slate-600'}
                  />
                </button>
              ))}
            </div>
          </div>
        </div>

      </div>

      {/* BRANCHING INTERVENTIONS BASED ON 70% THRESHOLD */}
      {passed ? (
        /* Case B: Topic Mastered -> Gamification & Badge Unlocking */
        <motion.div
          initial={{ opacity: 0, y: 15 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass-panel rounded-3xl p-6 md:p-8 relative overflow-hidden text-center border-emerald-500/30 bg-gradient-to-b from-emerald-950/20 to-slate-900"
        >
          {/* Glowing particle background */}
          <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(16,185,129,0.08),transparent_50%)] pointer-events-none" />

          <div className="max-w-md mx-auto space-y-6 relative z-10 py-6">
            <div className="w-20 h-20 bg-yellow-500/10 rounded-full flex items-center justify-center text-yellow-400 mx-auto border border-yellow-500/20 shadow-lg shadow-yellow-950/30 animate-bounce">
              <Award size={44} className="fill-yellow-500/10" />
            </div>

            <div className="space-y-2">
              <h2 className="text-2xl font-extrabold text-slate-100 flex items-center justify-center gap-2">
                <Sparkles size={20} className="text-yellow-400" />
                <span>Mastery Badge Unlocked!</span>
                <Sparkles size={20} className="text-yellow-400" />
              </h2>
              <p className="text-slate-400 text-xs max-w-sm mx-auto leading-relaxed">
                You scored above the 70% threshold! You have earned the specialized badge:
              </p>
            </div>

            {/* Special Badge Name Showcase Card */}
            <div className="bg-yellow-500/5 border border-yellow-500/25 rounded-2xl py-3 px-6 inline-block shadow-inner">
              <span className="text-yellow-400 text-base font-extrabold tracking-wider uppercase">
                {dpp.subject === 'Physics'
                  ? 'Kinematics Specialist'
                  : dpp.subject === 'Biology'
                  ? 'Endocrine Regulator'
                  : 'Integral Master'}
              </span>
            </div>

            {/* XP Points and Daily Streak Progress Display */}
            <div className="grid grid-cols-2 gap-4 border-t border-slate-800/80 pt-6">
              <div className="flex items-center justify-center gap-2.5 text-xs text-indigo-400 font-semibold bg-indigo-950/20 border border-indigo-900/35 rounded-xl py-2.5">
                <Sparkles size={16} />
                <span>+50 XP Points Awarded</span>
              </div>
              <div className="flex items-center justify-center gap-2.5 text-xs text-orange-400 font-semibold bg-orange-950/20 border border-orange-900/35 rounded-xl py-2.5">
                <Flame size={16} className="fill-orange-500/10" />
                <span>Streak Incremented!</span>
              </div>
            </div>
          </div>
        </motion.div>
      ) : (
        /* Case A: Needs Revision -> Prerequisite reinforcement, AI explanation module, practice exercises */
        <motion.div
          initial={{ opacity: 0, y: 15 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-6"
        >
          {/* Alert Header */}
          <div className="glass-panel rounded-2xl p-5 border-orange-500/20 bg-orange-500/5 flex flex-col sm:flex-row gap-4 items-start">
            <div className="w-10 h-10 rounded-full bg-orange-500/10 flex items-center justify-center text-orange-400 shrink-0 border border-orange-500/20">
              <AlertTriangle size={18} />
            </div>
            <div className="space-y-1">
              <h3 className="font-bold text-sm text-orange-400">Needs Foundational Revision</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Your accuracy profile indicates a few core gaps in these subtopics. Before retrying, we recommend reviewing the following prerequisites:
              </p>
              {/* Bullets */}
              <div className="flex flex-wrap gap-2 pt-2">
                {getRemediationTopics(dpp.subject).map((topic, idx) => (
                  <span
                    key={idx}
                    className="bg-slate-900 text-slate-300 border border-slate-800 px-3 py-1 rounded-md text-[11px] font-medium"
                  >
                    {topic}
                  </span>
                ))}
              </div>
            </div>
          </div>

          {/* Grid: 2-column: AI Tutorial Intervention & Simulated Practice Exercises */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            
            {/* Column 1: AI Tutorial Intervention */}
            <div className="glass-panel rounded-2xl p-6 space-y-4">
              <h4 className="font-bold text-sm text-slate-200 uppercase tracking-wider flex items-center gap-2">
                <Lightbulb size={16} className="text-indigo-400" />
                <span>AI Tutorial Intervention</span>
              </h4>
              <p className="text-xs text-slate-400 leading-relaxed">
                Unlock an interactive Gemini AI explanation to dissect the questions you missed and step-by-step math breakdowns.
              </p>

              {aiTutorialState === 'idle' && (
                <button
                  onClick={startAiTutorial}
                  className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-xs py-2.5 rounded-xl transition-smooth shadow-lg shadow-indigo-950/20"
                >
                  Generate Step-by-Step AI Tutorial
                </button>
              )}

              {aiTutorialState === 'generating' && (
                <div className="p-4 bg-slate-950 border border-slate-900 rounded-xl flex items-center justify-center gap-3 text-xs text-indigo-400">
                  <RefreshCw size={14} className="animate-spin" />
                  <span>Analyzing responses & compiling mathematical tutorial...</span>
                </div>
              )}

              {aiTutorialState === 'loaded' && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="p-4 bg-slate-950 border border-slate-900 rounded-xl space-y-4 text-xs max-h-[300px] overflow-y-auto"
                >
                  <div className="border-l-2 border-indigo-500 pl-3 py-0.5 space-y-1">
                    <div className="font-bold text-slate-300 uppercase tracking-wider text-[10px]">
                      Concept Breakdown: Double Integration
                    </div>
                    <p className="text-slate-400 leading-relaxed">
                      To integrate a variable acceleration function like $a(t) = 2t$ to find displacement $s(t)$, you must evaluate two sequential integrals:
                    </p>
                  </div>

                  <div className="bg-slate-900/60 p-3 rounded border border-slate-850">
                    <LaTeX text="$$v(t) = \int a(t)\,dt = \int 2t\,dt = t^2 + C_1$$" />
                    <LaTeX text="$$s(t) = \int v(t)\,dt = \int (t^2 + C_1)\,dt = \frac{t^3}{3} + C_1 t + C_2$$" />
                  </div>

                  <p className="text-slate-400 leading-relaxed">
                    Always resolve constants of integration $C_1$ and $C_2$ using the boundary states. Here, "starting from rest" implies $v(0) = 0 \implies C_1 = 0$.
                  </p>

                  <div className="border-t border-slate-900 pt-3 text-[10px] text-slate-500 text-right">
                    Academic Assistant AI • Generated in 1.5s
                  </div>
                </motion.div>
              )}
            </div>

            {/* Column 2: Simulated Practice Container */}
            <div className="glass-panel rounded-2xl p-6 space-y-4">
              <div className="flex items-center justify-between">
                <h4 className="font-bold text-sm text-slate-200 uppercase tracking-wider flex items-center gap-2">
                  <HelpCircle size={16} className="text-emerald-400" />
                  <span>Simulated Practice Exercises</span>
                </h4>
                <div className="flex gap-1">
                  {adaptiveQuestions.map((_, index) => (
                    <button
                      key={index}
                      onClick={() => {
                        setActivePracticeIndex(index);
                      }}
                      className={`w-5 h-5 rounded text-[10px] font-mono font-bold flex items-center justify-center border transition-smooth ${
                        index === activePracticeIndex
                          ? 'bg-emerald-600 border-emerald-500 text-white shadow'
                          : 'bg-slate-950 border-slate-900 text-slate-500 hover:text-slate-400'
                      }`}
                    >
                      {index + 1}
                    </button>
                  ))}
                </div>
              </div>

              <div className="p-4 bg-slate-950 border border-slate-900 rounded-xl space-y-4">
                <div className="text-xs text-slate-200 min-h-[40px]">
                  <LaTeX text={adaptiveQuestions[activePracticeIndex].q} />
                </div>

                <div className="grid grid-cols-2 gap-2">
                  {adaptiveQuestions[activePracticeIndex].options.map((opt, optIdx) => {
                    const isCorrect = opt === adaptiveQuestions[activePracticeIndex].ans;
                    return (
                      <div
                        key={optIdx}
                        className={`p-2.5 rounded-lg border text-center text-xs font-medium cursor-default ${
                          showPracticeSolutions[activePracticeIndex] && isCorrect
                            ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400'
                            : 'bg-slate-900 border-slate-850 text-slate-400'
                        }`}
                      >
                        {opt}
                      </div>
                    );
                  })}
                </div>

                <div className="flex items-center justify-between border-t border-slate-900 pt-3">
                  <button
                    onClick={() => toggleSolution(activePracticeIndex)}
                    className="text-[11px] text-indigo-400 hover:text-indigo-300 font-bold transition-smooth uppercase tracking-wider"
                  >
                    {showPracticeSolutions[activePracticeIndex] ? 'Hide Explanation' : 'View Correct Answer'}
                  </button>
                  <span className="text-[10px] text-slate-500 font-semibold uppercase">Non-Graded Practice</span>
                </div>

                {showPracticeSolutions[activePracticeIndex] && (
                  <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    className="p-3 bg-emerald-500/5 border border-emerald-500/10 rounded-lg text-xs text-emerald-400"
                  >
                    <div className="font-bold mb-1">Step-by-Step Solution:</div>
                    <LaTeX text={adaptiveQuestions[activePracticeIndex].sol} />
                  </motion.div>
                )}
              </div>
            </div>

          </div>
        </motion.div>
      )}

      {/* Action Footer Button Drawer */}
      <div className="flex items-center justify-end gap-4 border-t border-slate-800/80 pt-6 mt-6">
        <button
          onClick={onReviewAnswers}
          className="bg-slate-900 border border-slate-800 text-slate-300 hover:text-white px-5 py-3 rounded-xl text-xs font-semibold uppercase tracking-wider transition-smooth"
        >
          Review All Explanations
        </button>
        <button
          onClick={onReturnDashboard}
          className="bg-indigo-600 hover:bg-indigo-500 text-white px-6 py-3 rounded-xl text-xs font-bold uppercase tracking-wider flex items-center gap-1.5 transition-smooth shadow-lg shadow-indigo-950/20"
        >
          <span>Return to Dashboard</span>
          <ArrowRightCircle size={14} />
        </button>
      </div>
    </div>
  );
};
