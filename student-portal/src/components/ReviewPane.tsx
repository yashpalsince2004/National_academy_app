import React from 'react';
import type { DPP, DPPAttempt } from '../types';
import { LaTeX } from './LaTeX';
import { CheckCircle2, XCircle, HelpCircle, ArrowLeft, Lightbulb } from 'lucide-react';

interface ReviewPaneProps {
  dpp: DPP;
  attempt: DPPAttempt;
  onBackToResult: () => void;
}

export const ReviewPane: React.FC<ReviewPaneProps> = ({
  dpp,
  attempt,
  onBackToResult,
}) => {
  const optionLetters = ['A', 'B', 'C', 'D'];

  const getOptionStyle = (
    questionId: string,
    optionLetter: string,
    correctAnswer: string
  ) => {
    const studentAns = attempt.savedAnswers[questionId];
    const isSelected = studentAns === optionLetter;
    const isCorrect = correctAnswer === optionLetter;

    if (isSelected) {
      if (isCorrect) {
        return 'bg-emerald-500/10 border-emerald-500 shadow-md shadow-emerald-950/10 text-emerald-300';
      } else {
        return 'bg-red-500/10 border-red-500 shadow-md shadow-red-950/10 text-red-300';
      }
    }

    if (isCorrect) {
      // Highlight the correct answer if skipped or chosen wrongly
      return 'bg-slate-900 border-dashed border-emerald-500/50 text-emerald-400';
    }

    return 'bg-slate-900/40 border-slate-800 text-slate-400';
  };

  const getOptionBadgeStyle = (
    questionId: string,
    optionLetter: string,
    correctAnswer: string
  ) => {
    const studentAns = attempt.savedAnswers[questionId];
    const isSelected = studentAns === optionLetter;
    const isCorrect = correctAnswer === optionLetter;

    if (isSelected) {
      if (isCorrect) {
        return 'bg-emerald-600 border-emerald-500 text-white';
      } else {
        return 'bg-red-600 border-red-500 text-white';
      }
    }

    if (isCorrect) {
      return 'bg-emerald-600/20 border-emerald-500/45 text-emerald-400';
    }

    return 'bg-slate-950 border-slate-800 text-slate-500';
  };

  return (
    <div className="space-y-6 animate-fade-in pb-16">
      {/* Header controls */}
      <div className="glass-panel rounded-2xl p-4 flex items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <button
            onClick={onBackToResult}
            className="flex items-center gap-1.5 text-slate-400 hover:text-white transition-smooth text-xs font-semibold uppercase tracking-wider border border-slate-800 rounded-lg px-3 py-2 bg-slate-950/40"
          >
            <ArrowLeft size={14} />
            <span>Result Scorecard</span>
          </button>
          <div className="h-5 w-px bg-slate-800" />
          <div>
            <h2 className="font-bold text-sm text-slate-200">Detailed Explanations</h2>
            <p className="text-[10px] text-slate-500 uppercase tracking-widest">{dpp.name}</p>
          </div>
        </div>

        <span className="text-xs text-slate-500">
          Accuracy: <span className="text-slate-300 font-mono font-bold">{(attempt.score || 0).toFixed(0)}%</span>
        </span>
      </div>

      {/* Questions Stack */}
      <div className="space-y-6">
        {dpp.questions.map((q, idx) => {
          const studentAns = attempt.savedAnswers[q.id];
          const isCorrect = studentAns === q.correctAnswer;
          const isSkipped = !studentAns;

          return (
            <div
              key={q.id}
              className={`glass-panel rounded-2xl p-6 md:p-8 space-y-6 border-l-4 ${
                isSkipped
                  ? 'border-l-slate-600'
                  : isCorrect
                  ? 'border-l-emerald-500'
                  : 'border-l-red-500'
              }`}
            >
              {/* Question status header */}
              <div className="flex items-center justify-between border-b border-slate-800/80 pb-4">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-bold text-slate-500 uppercase">
                    Question {idx + 1}
                  </span>
                  <div className="h-3 w-px bg-slate-800" />
                  {isSkipped ? (
                    <div className="flex items-center gap-1 text-[11px] font-bold text-slate-400">
                      <HelpCircle size={12} />
                      <span>Skipped</span>
                    </div>
                  ) : isCorrect ? (
                    <div className="flex items-center gap-1 text-[11px] font-bold text-emerald-400">
                      <CheckCircle2 size={12} />
                      <span>Correct</span>
                    </div>
                  ) : (
                    <div className="flex items-center gap-1 text-[11px] font-bold text-red-400">
                      <XCircle size={12} />
                      <span>Incorrect (Selected {studentAns})</span>
                    </div>
                  )}
                </div>

                <div className="text-[11px] text-slate-500">
                  Topic Outcome: <span className="text-slate-300 font-medium">{q.learningOutcome || 'General'}</span>
                </div>
              </div>

              {/* Question text */}
              <div className="text-slate-100 text-base md:text-lg">
                <LaTeX text={q.question} />
              </div>

              {/* Options */}
              <div className="space-y-2.5">
                {q.options.map((option, optIdx) => {
                  const letter = optionLetters[optIdx];
                  const optStyle = getOptionStyle(q.id, letter, q.correctAnswer);
                  const badgeStyle = getOptionBadgeStyle(q.id, letter, q.correctAnswer);

                  return (
                    <div
                      key={optIdx}
                      className={`w-full p-3.5 rounded-xl border flex items-center gap-4 transition-smooth min-h-[44px] ${optStyle}`}
                    >
                      <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold border transition-smooth ${badgeStyle}`}>
                        {letter}
                      </div>
                      <div className="flex-1 text-sm font-medium">
                        <LaTeX text={option} />
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* rigourous step-by-step explanation */}
              <div className="bg-slate-950 border border-slate-900 rounded-xl p-5 space-y-3">
                <h4 className="text-xs font-bold text-slate-400 uppercase tracking-widest flex items-center gap-1.5">
                  <Lightbulb size={14} className="text-yellow-400" />
                  <span>Rigorous Step-by-Step Explanation</span>
                </h4>
                <div className="text-xs text-slate-300 leading-relaxed">
                  <LaTeX text={q.explanation} />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Back button at the end */}
      <div className="flex justify-start">
        <button
          onClick={onBackToResult}
          className="bg-slate-900 border border-slate-800 text-slate-300 hover:text-white px-5 py-2.5 rounded-xl text-xs font-semibold uppercase tracking-wider transition-smooth"
        >
          Back to Scorecard
        </button>
      </div>
    </div>
  );
};
