import React from 'react';
import type { DPP, DPPAttempt } from '../types';
import { LaTeX } from './LaTeX';
import { motion, AnimatePresence } from 'framer-motion';
import { Timer, LayoutGrid, Layers, ArrowLeft, ArrowRight, Save, CheckCircle2 } from 'lucide-react';

interface DppSolvingEngineProps {
  dpp: DPP;
  initialAttempt?: DPPAttempt;
  onSaveDraft: (answers: Record<string, string>, elapsedSeconds: number) => void;
  onSubmit: (answers: Record<string, string>, elapsedSeconds: number) => void;
}

export const DppSolvingEngine: React.FC<DppSolvingEngineProps> = ({
  dpp,
  initialAttempt,
  onSaveDraft,
  onSubmit,
}) => {
  const [attemptMode, setAttemptMode] = React.useState<'Sprint' | 'FullSheet'>('Sprint');
  const [currentIndex, setCurrentIndex] = React.useState<number>(0);
  const [answers, setAnswers] = React.useState<Record<string, string>>(
    initialAttempt?.savedAnswers || {}
  );

  // Timer states
  const [secondsElapsed, setSecondsElapsed] = React.useState<number>(
    initialAttempt?.timeSpent || 0
  );

  // Increment total timer
  React.useEffect(() => {
    const interval = setInterval(() => {
      setSecondsElapsed((prev) => prev + 1);
    }, 1000);

    return () => clearInterval(interval);
  }, []);


  const handleSelectOption = (questionId: string, optionLetter: string) => {
    setAnswers((prev) => ({
      ...prev,
      [questionId]: optionLetter,
    }));
  };

  const handleClearAnswer = (questionId: string) => {
    setAnswers((prev) => {
      const copy = { ...prev };
      delete copy[questionId];
      return copy;
    });
  };

  const formatTimer = (totalSeconds: number) => {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const secs = totalSeconds % 60;
    return `${hours > 0 ? `${hours}:` : ''}${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  // Compute stats
  const totalQuestions = dpp.questions.length;
  const answeredCount = Object.keys(answers).length;
  const avgTimePerQuestion = answeredCount > 0 ? secondsElapsed / answeredCount : 0;

  const currentQuestion = dpp.questions[currentIndex];
  const optionLetters = ['A', 'B', 'C', 'D'];

  const triggerSaveDraft = () => {
    onSaveDraft(answers, secondsElapsed);
  };

  const triggerSubmit = () => {
    onSubmit(answers, secondsElapsed);
  };

  return (
    <div className="space-y-6 animate-fade-in pb-16">
      {/* Test Controls Bar */}
      <div className="glass-panel rounded-2xl p-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
        {/* Left Side: Test Title & Mode Toggles */}
        <div className="flex flex-wrap items-center gap-4">
          <button
            onClick={triggerSaveDraft}
            className="flex items-center gap-1.5 text-slate-400 hover:text-white transition-smooth text-xs font-semibold uppercase tracking-wider border border-slate-800 rounded-lg px-3 py-2 bg-slate-950/40"
          >
            <ArrowLeft size={14} />
            <span>Save & Exit</span>
          </button>
          
          <div className="h-5 w-px bg-slate-800 hidden sm:block" />

          <div>
            <h2 className="font-bold text-base text-white">{dpp.name}</h2>
            <p className="text-xs text-slate-400 font-mono">{dpp.subject} | {dpp.batch}</p>
          </div>
        </div>

        {/* Right Side: Attempt Modes & Dynamic Timer */}
        <div className="flex flex-wrap items-center gap-4 justify-between md:justify-end">
          {/* Mode Switcher */}
          <div className="flex bg-slate-950 p-1 rounded-xl border border-slate-900">
            <button
              onClick={() => setAttemptMode('Sprint')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-smooth ${
                attemptMode === 'Sprint'
                  ? 'bg-slate-800 text-white shadow'
                  : 'text-slate-500 hover:text-slate-300'
              }`}
            >
              <Layers size={14} />
              <span>Sprint</span>
            </button>
            <button
              onClick={() => setAttemptMode('FullSheet')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-smooth ${
                attemptMode === 'FullSheet'
                  ? 'bg-slate-800 text-white shadow'
                  : 'text-slate-500 hover:text-slate-300'
              }`}
            >
              <LayoutGrid size={14} />
              <span>Full Sheet</span>
            </button>
          </div>

          {/* Timers Panel */}
          <div className="flex items-center gap-4 bg-slate-950 border border-slate-900 rounded-xl px-4 py-1.5">
            {/* Total Timer */}
            <div className="flex items-center gap-2">
              <Timer size={16} className="text-indigo-400" />
              <div className="font-mono text-sm font-bold text-slate-100 min-w-[50px] text-right">
                {formatTimer(secondsElapsed)}
              </div>
            </div>
            {/* Avg Timer */}
            <div className="h-4 w-px bg-slate-800" />
            <div className="text-[11px] text-slate-500">
              Avg/Q: <span className="font-mono text-slate-300 font-semibold">{formatTimer(Math.round(avgTimePerQuestion))}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Main Attempt Container */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 items-start">
        
        {/* Answering Panels */}
        <div className="lg:col-span-3 space-y-6">
          <AnimatePresence mode="wait">
            {attemptMode === 'Sprint' ? (
              <motion.div
                key={currentIndex}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.18 }}
                className="glass-panel rounded-2xl p-6 md:p-8 space-y-6"
              >
                {/* Header info */}
                <div className="flex items-center justify-between border-b border-slate-800/80 pb-4">
                  <div className="text-xs text-slate-400 font-semibold">
                    QUESTION {currentIndex + 1} OF {totalQuestions}
                  </div>
                  {currentQuestion?.difficulty && (
                    <span className={`px-2.5 py-0.5 rounded text-[11px] font-bold ${
                      currentQuestion.difficulty === 'Easy'
                        ? 'bg-emerald-500/10 text-emerald-400'
                        : currentQuestion.difficulty === 'Medium'
                        ? 'bg-orange-500/10 text-orange-400'
                        : 'bg-red-500/10 text-red-400'
                    }`}>
                      {currentQuestion.difficulty}
                    </span>
                  )}
                </div>

                {/* Question Body */}
                <div className="text-slate-100 text-lg">
                  <LaTeX text={currentQuestion.question} />
                </div>

                {/* Options List */}
                <div className="space-y-3 pt-4">
                  {currentQuestion.options.map((option, optIdx) => {
                    const letter = optionLetters[optIdx];
                    const isSelected = answers[currentQuestion.id] === letter;

                    return (
                      <button
                        key={optIdx}
                        onClick={() => handleSelectOption(currentQuestion.id, letter)}
                        className={`w-full text-left p-4 rounded-xl border flex items-center gap-4 transition-smooth min-h-[48px] ${
                          isSelected
                            ? 'bg-indigo-600/10 border-indigo-500 shadow-md shadow-indigo-950/20'
                            : 'bg-slate-900/30 border-slate-800 hover:border-slate-700 hover:bg-slate-900/50'
                        }`}
                      >
                        {/* Styled choice circle */}
                        <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold border transition-smooth ${
                          isSelected
                            ? 'bg-indigo-600 border-indigo-500 text-white'
                            : 'bg-slate-950 border-slate-800 text-slate-400'
                        }`}>
                          {letter}
                        </div>
                        <div className="flex-1 text-slate-200">
                          <LaTeX text={option} />
                        </div>
                      </button>
                    );
                  })}
                </div>

                {/* Question Actions */}
                <div className="flex items-center justify-between border-t border-slate-800/80 pt-6 mt-6">
                  <button
                    onClick={() => handleClearAnswer(currentQuestion.id)}
                    disabled={!answers[currentQuestion.id]}
                    className="text-xs text-slate-500 hover:text-slate-300 font-semibold disabled:opacity-30 disabled:hover:text-slate-500 transition-smooth uppercase tracking-wider"
                  >
                    Clear Response
                  </button>

                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => setCurrentIndex((prev) => Math.max(0, prev - 1))}
                      disabled={currentIndex === 0}
                      className="bg-slate-900 border border-slate-800 text-slate-300 hover:text-white px-4 py-2.5 rounded-xl text-xs font-semibold uppercase tracking-wider flex items-center gap-1.5 transition-smooth disabled:opacity-40"
                    >
                      <ArrowLeft size={14} />
                      <span>Back</span>
                    </button>

                    {currentIndex < totalQuestions - 1 ? (
                      <button
                        onClick={() => setCurrentIndex((prev) => Math.min(totalQuestions - 1, prev + 1))}
                        className="bg-indigo-600 hover:bg-indigo-500 text-white px-5 py-2.5 rounded-xl text-xs font-semibold uppercase tracking-wider flex items-center gap-1.5 transition-smooth"
                      >
                        <span>Next</span>
                        <ArrowRight size={14} />
                      </button>
                    ) : (
                      <button
                        onClick={triggerSubmit}
                        className="bg-emerald-600 hover:bg-emerald-500 text-white px-6 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider flex items-center gap-1.5 shadow-lg shadow-emerald-950/20 transition-smooth"
                      >
                        <CheckCircle2 size={14} />
                        <span>Submit Test</span>
                      </button>
                    )}
                  </div>
                </div>
              </motion.div>
            ) : (
              // Full Sheet Layout: vertical scrolling list of all questions
              <div className="space-y-6">
                {dpp.questions.map((q, idx) => {
                  const selectedVal = answers[q.id];
                  return (
                    <div key={q.id} id={`q-sheet-${idx}`} className="glass-panel rounded-2xl p-6 md:p-8 space-y-6">
                      <div className="flex items-center justify-between border-b border-slate-800/80 pb-4">
                        <div className="text-xs text-indigo-400 font-bold uppercase tracking-wider">
                          Question {idx + 1}
                        </div>
                        {q.difficulty && (
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            q.difficulty === 'Easy'
                              ? 'bg-emerald-500/10 text-emerald-400'
                              : q.difficulty === 'Medium'
                              ? 'bg-orange-500/10 text-orange-400'
                              : 'bg-red-500/10 text-red-400'
                          }`}>
                            {q.difficulty}
                          </span>
                        )}
                      </div>

                      <div className="text-slate-100 text-base">
                        <LaTeX text={q.question} />
                      </div>

                      <div className="space-y-2.5 pt-2">
                        {q.options.map((option, optIdx) => {
                          const letter = optionLetters[optIdx];
                          const isSelected = selectedVal === letter;
                          return (
                            <button
                              key={optIdx}
                              onClick={() => handleSelectOption(q.id, letter)}
                              className={`w-full text-left p-3.5 rounded-xl border flex items-center gap-4 transition-smooth min-h-[44px] ${
                                isSelected
                                  ? 'bg-indigo-600/10 border-indigo-500'
                                  : 'bg-slate-900/30 border-slate-800 hover:border-slate-700'
                              }`}
                            >
                              <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold border transition-smooth ${
                                isSelected
                                  ? 'bg-indigo-600 border-indigo-500 text-white'
                                  : 'bg-slate-950 border-slate-800 text-slate-400'
                              }`}>
                                {letter}
                              </div>
                              <div className="flex-1 text-sm text-slate-200">
                                <LaTeX text={option} />
                              </div>
                            </button>
                          );
                        })}
                      </div>

                      <div className="flex justify-end pt-2">
                        <button
                          onClick={() => handleClearAnswer(q.id)}
                          disabled={!selectedVal}
                          className="text-[11px] text-slate-500 hover:text-slate-300 font-semibold disabled:opacity-30 transition-smooth uppercase tracking-wider"
                        >
                          Clear Choice
                        </button>
                      </div>
                    </div>
                  );
                })}

                {/* Final Submission Card at the bottom of full sheet */}
                <div className="glass-panel rounded-2xl p-6 text-center space-y-4">
                  <h3 className="font-bold text-lg text-slate-200">All Done?</h3>
                  <p className="text-xs text-slate-400 max-w-sm mx-auto">
                    You have answered {answeredCount} out of {totalQuestions} questions. Make sure to review your answers before submitting!
                  </p>
                  <button
                    onClick={triggerSubmit}
                    className="bg-emerald-600 hover:bg-emerald-500 text-white px-8 py-3 rounded-xl text-sm font-bold uppercase tracking-wider flex items-center gap-1.5 shadow-lg shadow-emerald-950/20 transition-smooth mx-auto"
                  >
                    <CheckCircle2 size={16} />
                    <span>Submit Challenge</span>
                  </button>
                </div>
              </div>
            )}
          </AnimatePresence>
        </div>

        {/* Side Panel: Quick Access Question Matrix Grid */}
        <div className="glass-panel rounded-2xl p-5 md:p-6 space-y-6 lg:sticky lg:top-28">
          <div className="space-y-1">
            <h3 className="font-bold text-sm text-slate-200 uppercase tracking-wider">
              Answering Ledger
            </h3>
            <p className="text-xs text-slate-400">
              Answered: <span className="text-indigo-400 font-bold">{answeredCount}</span>/{totalQuestions}
            </p>
          </div>

          {/* Nav Grid */}
          <div className="grid grid-cols-5 gap-2">
            {dpp.questions.map((q, idx) => {
              const hasAnswered = !!answers[q.id];
              const isCurrent = idx === currentIndex && attemptMode === 'Sprint';

              return (
                <button
                  key={q.id}
                  onClick={() => {
                    setCurrentIndex(idx);
                    if (attemptMode === 'FullSheet') {
                      // Scroll to target element
                      const element = document.getElementById(`q-sheet-${idx}`);
                      if (element) {
                        element.scrollIntoView({ behavior: 'smooth', block: 'center' });
                      }
                    }
                  }}
                  className={`w-9 h-9 rounded-lg text-xs font-mono font-bold border flex items-center justify-center transition-smooth ${
                    isCurrent
                      ? 'bg-indigo-600 border-indigo-500 text-white shadow-md'
                      : hasAnswered
                      ? 'bg-indigo-600/10 border-indigo-500/30 text-indigo-400'
                      : 'bg-slate-950 border-slate-900 text-slate-500 hover:border-slate-800 hover:text-slate-400'
                  }`}
                >
                  {idx + 1}
                </button>
              );
            })}
          </div>

          <div className="border-t border-slate-800/80 pt-4 space-y-2">
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <div className="w-3 h-3 rounded bg-indigo-600" />
              <span>Active</span>
            </div>
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <div className="w-3 h-3 rounded bg-indigo-600/15 border border-indigo-500/30" />
              <span>Answered</span>
            </div>
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <div className="w-3 h-3 rounded bg-slate-950 border border-slate-900" />
              <span>Not Attempted</span>
            </div>
          </div>

          {/* Quick Actions Drawer */}
          <div className="border-t border-slate-800/80 pt-4 space-y-3">
            <button
              onClick={triggerSaveDraft}
              className="w-full bg-slate-900 border border-slate-850 hover:bg-slate-850 text-slate-300 hover:text-white py-2 rounded-xl text-xs font-semibold transition-smooth flex items-center justify-center gap-2"
            >
              <Save size={14} />
              <span>Save Progress</span>
            </button>
          </div>
        </div>

      </div>
    </div>
  );
};
