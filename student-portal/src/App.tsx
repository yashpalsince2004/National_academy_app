import React from 'react';
import type { DPP, DPPAttempt, StudentProfile } from './types';
import { initialStudentProfile, mockDpps } from './mockData';
import { DppDashboard } from './components/DppDashboard';
import { DppSolvingEngine } from './components/DppSolvingEngine';
import { ResultProfile } from './components/ResultProfile';
import { ReviewPane } from './components/ReviewPane';
import { GraduationCap, RefreshCw } from 'lucide-react';

export default function App() {
  const [viewState, setViewState] = React.useState<'dashboard' | 'attempt' | 'result' | 'review'>('dashboard');
  const [activeDpp, setActiveDpp] = React.useState<DPP | null>(null);
  const [student, setStudent] = React.useState<StudentProfile>(() => {
    const saved = localStorage.getItem('na-student-profile');
    return saved ? JSON.parse(saved) : initialStudentProfile;
  });

  const [attempts, setAttempts] = React.useState<Record<string, DPPAttempt>>(() => {
    const saved = localStorage.getItem('na-dpp-attempts');
    return saved ? JSON.parse(saved) : {};
  });

  // Save state to localStorage whenever it changes
  React.useEffect(() => {
    localStorage.setItem('na-dpp-attempts', JSON.stringify(attempts));
  }, [attempts]);

  React.useEffect(() => {
    localStorage.setItem('na-student-profile', JSON.stringify(student));
  }, [student]);

  const handleStartDpp = (dpp: DPP) => {
    setActiveDpp(dpp);
    setViewState('attempt');
  };

  const handleReviewDpp = (dpp: DPP) => {
    setActiveDpp(dpp);
    setViewState('review');
  };

  const handleSaveDraft = (answers: Record<string, string>, elapsedSeconds: number) => {
    if (!activeDpp) return;

    setAttempts((prev) => ({
      ...prev,
      [activeDpp.id]: {
        dppId: activeDpp.id,
        status: 'IN_PROGRESS',
        savedAnswers: answers,
        timeSpent: elapsedSeconds,
      },
    }));

    // Alert user
    alert('Draft saved successfully! You can resume this attempt anytime.');
    setViewState('dashboard');
    setActiveDpp(null);
  };

  const handleSubmitAttempt = (answers: Record<string, string>, elapsedSeconds: number) => {
    if (!activeDpp) return;

    // Grade attempt
    let correctCount = 0;
    let wrongCount = 0;
    let skippedCount = 0;

    activeDpp.questions.forEach((q) => {
      const studentAns = answers[q.id];
      if (!studentAns) {
        skippedCount++;
      } else if (studentAns.trim().toUpperCase() === q.correctAnswer.trim().toUpperCase()) {
        correctCount++;
      } else {
        wrongCount++;
      }
    });

    const totalQs = activeDpp.questions.length;
    const scorePercent = totalQs > 0 ? (correctCount / totalQs) * 100 : 0;
    const isSuccess = scorePercent >= 70;

    const newAttempt: DPPAttempt = {
      dppId: activeDpp.id,
      status: 'COMPLETED',
      savedAnswers: answers,
      score: scorePercent,
      timeSpent: elapsedSeconds,
      completedAt: new Date().toISOString(),
      correctCount,
      wrongCount,
      skippedCount,
    };

    setAttempts((prev) => ({
      ...prev,
      [activeDpp.id]: newAttempt,
    }));

    // Apply gamification if passing
    if (isSuccess) {
      // Get badge name
      let badgeName = 'Integral Master';
      if (activeDpp.subject === 'Physics') badgeName = 'Kinematics Specialist';
      else if (activeDpp.subject === 'Biology') badgeName = 'Endocrine Regulator';

      setStudent((prev) => {
        const alreadyHasBadge = prev.unlockedBadges.includes(badgeName);
        return {
          ...prev,
          xp: prev.xp + 50,
          streak: prev.streak + 1,
          unlockedBadges: alreadyHasBadge
            ? prev.unlockedBadges
            : [...prev.unlockedBadges, badgeName],
        };
      });
    }

    setViewState('result');
  };

  const handleResetData = () => {
    if (window.confirm('Are you sure you want to clear all practice attempts and reset stats?')) {
      localStorage.removeItem('na-dpp-attempts');
      localStorage.removeItem('na-student-profile');
      setAttempts({});
      setStudent(initialStudentProfile);
      setViewState('dashboard');
      setActiveDpp(null);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans">
      {/* Navigation Header */}
      <header className="border-b border-slate-900 bg-slate-950/80 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 to-indigo-400 flex items-center justify-center text-white shadow-lg shadow-indigo-900/30">
              <GraduationCap size={22} />
            </div>
            <div>
              <span className="font-extrabold text-base tracking-tight text-white">National Academy</span>
              <span className="text-[10px] text-indigo-400 font-bold block uppercase tracking-wider -mt-1">
                Student Portal
              </span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <button
              onClick={handleResetData}
              title="Reset All Local Data"
              className="p-2 rounded-lg border border-slate-800 text-slate-500 hover:text-slate-300 hover:bg-slate-900 transition-smooth"
            >
              <RefreshCw size={14} />
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 w-full">
        {viewState === 'dashboard' && (
          <DppDashboard
            dpps={mockDpps}
            attempts={attempts}
            student={student}
            onStartDpp={handleStartDpp}
            onReviewDpp={handleReviewDpp}
          />
        )}

        {viewState === 'attempt' && activeDpp && (
          <DppSolvingEngine
            dpp={activeDpp}
            initialAttempt={attempts[activeDpp.id]}
            onSaveDraft={handleSaveDraft}
            onSubmit={handleSubmitAttempt}
          />
        )}

        {viewState === 'result' && activeDpp && attempts[activeDpp.id] && (
          <ResultProfile
            dpp={activeDpp}
            attempt={attempts[activeDpp.id]}
            onReviewAnswers={() => setViewState('review')}
            onReturnDashboard={() => {
              setViewState('dashboard');
              setActiveDpp(null);
            }}
          />
        )}

        {viewState === 'review' && activeDpp && attempts[activeDpp.id] && (
          <ReviewPane
            dpp={activeDpp}
            attempt={attempts[activeDpp.id]}
            onBackToResult={() => {
              // If attempt is completed, back goes to results. Otherwise back to dashboard.
              setViewState(attempts[activeDpp.id].status === 'COMPLETED' ? 'result' : 'dashboard');
            }}
          />
        )}
      </main>

      {/* Corporate/Academic Footer */}
      <footer className="border-t border-slate-900 py-6 text-center text-[10px] text-slate-600 bg-slate-950/40">
        <p>© 2026 National Academy Group. All rights reserved. Competitive Exam LMS solved attempt ledger v1.2</p>
      </footer>
    </div>
  );
}
