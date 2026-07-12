import React from 'react';
import type { DPP, DPPAttempt, StudentProfile } from '../types';
import { BookOpen, Flame, Sparkles, Award, Clock, ArrowRight, CheckCircle, Play } from 'lucide-react';

interface DppDashboardProps {
  dpps: DPP[];
  attempts: Record<string, DPPAttempt>;
  student: StudentProfile;
  onStartDpp: (dpp: DPP) => void;
  onReviewDpp: (dpp: DPP) => void;
}

export const DppDashboard: React.FC<DppDashboardProps> = ({
  dpps,
  attempts,
  student,
  onStartDpp,
  onReviewDpp,
}) => {
  const [selectedSubject, setSelectedSubject] = React.useState<string>('All');
  const [selectedStatus, setSelectedStatus] = React.useState<'TODO' | 'IN_PROGRESS' | 'COMPLETED'>('TODO');

  const subjects = ['All', 'Physics', 'Chemistry', 'Mathematics', 'Biology'];

  const getDppStatus = (dppId: string): 'TODO' | 'IN_PROGRESS' | 'COMPLETED' => {
    return attempts[dppId]?.status || 'TODO';
  };

  const getSubjectColor = (sub: string) => {
    switch (sub.toLowerCase()) {
      case 'physics':
        return 'bg-blue-500/10 text-blue-400 border-blue-500/30';
      case 'chemistry':
        return 'bg-teal-500/10 text-teal-400 border-teal-500/30';
      case 'mathematics':
        return 'bg-purple-500/10 text-purple-400 border-purple-500/30';
      case 'biology':
        return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30';
      default:
        return 'bg-slate-500/10 text-slate-400 border-slate-500/30';
    }
  };

  // Filter DPPs based on subject and status
  const filteredDpps = dpps.filter((dpp) => {
    const matchSubject = selectedSubject === 'All' || dpp.subject === selectedSubject;
    const matchStatus = getDppStatus(dpp.id) === selectedStatus;
    return matchSubject && matchStatus;
  });

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Student Profile Header Banner */}
      <div className="glass-panel rounded-2xl p-6 md:p-8 flex flex-col md:flex-row md:items-center justify-between gap-6 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-96 h-96 bg-indigo-500/10 rounded-full blur-3xl -z-10" />
        <div className="space-y-2">
          <div className="flex items-center gap-2 text-indigo-400 font-semibold text-sm tracking-wider uppercase">
            <Sparkles size={16} />
            <span>National Academy Portal</span>
          </div>
          <h1 className="text-3xl md:text-4xl font-bold tracking-tight text-white">
            Welcome back, {student.name}
          </h1>
          <p className="text-slate-400 text-sm">
            Roll No: <span className="font-mono text-slate-300">{student.rollNo}</span> | Active Batch: <span className="text-slate-300 font-semibold">{student.batch}</span>
          </p>
        </div>

        {/* Stats Widget Container */}
        <div className="flex flex-wrap items-center gap-4">
          {/* Streak */}
          <div className="bg-slate-900/80 border border-slate-800 rounded-xl px-5 py-3 flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-orange-500/10 flex items-center justify-center text-orange-400">
              <Flame size={20} className="fill-orange-500/20" />
            </div>
            <div>
              <div className="text-xs text-slate-500 font-medium">Daily Streak</div>
              <div className="text-lg font-bold text-slate-100">{student.streak} Days</div>
            </div>
          </div>

          {/* XP */}
          <div className="bg-slate-900/80 border border-slate-800 rounded-xl px-5 py-3 flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-indigo-500/10 flex items-center justify-center text-indigo-400">
              <Sparkles size={20} />
            </div>
            <div>
              <div className="text-xs text-slate-500 font-medium">Total XP</div>
              <div className="text-lg font-bold text-slate-100">{student.xp} XP</div>
            </div>
          </div>

          {/* Badges Count */}
          <div className="bg-slate-900/80 border border-slate-800 rounded-xl px-5 py-3 flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-yellow-500/10 flex items-center justify-center text-yellow-400">
              <Award size={20} />
            </div>
            <div>
              <div className="text-xs text-slate-500 font-medium">Mastery Badges</div>
              <div className="text-lg font-bold text-slate-100">{student.unlockedBadges.length}</div>
            </div>
          </div>
        </div>
      </div>

      {/* Mastery Badges Showcase shelf */}
      {student.unlockedBadges.length > 0 && (
        <div className="flex flex-col gap-3">
          <h3 className="text-sm font-semibold text-slate-400 tracking-wider uppercase flex items-center gap-2">
            <Award size={16} className="text-yellow-400" />
            <span>Unlocked Mastery Badges</span>
          </h3>
          <div className="flex flex-wrap gap-3">
            {student.unlockedBadges.map((badge, idx) => (
              <div
                key={idx}
                className="bg-yellow-500/5 border border-yellow-500/20 rounded-full px-4 py-1.5 text-xs text-yellow-400 font-medium flex items-center gap-2 shadow-sm"
              >
                <Award size={12} className="fill-yellow-500/10" />
                <span>{badge}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Filter and Content Controls Section */}
      <div className="flex flex-col md:flex-row gap-4 md:items-center justify-between border-b border-slate-800/80 pb-4">
        {/* Status Tabs */}
        <div className="flex bg-slate-950 p-1 rounded-xl border border-slate-900 self-start">
          {(['TODO', 'IN_PROGRESS', 'COMPLETED'] as const).map((status) => (
            <button
              key={status}
              onClick={() => setSelectedStatus(status)}
              className={`px-4 py-2 rounded-lg text-xs font-semibold uppercase tracking-wider transition-smooth ${
                selectedStatus === status
                  ? 'bg-indigo-600 text-white shadow-lg'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              {status === 'TODO'
                ? 'Assigned'
                : status === 'IN_PROGRESS'
                ? 'In Progress'
                : 'Completed'}
            </button>
          ))}
        </div>

        {/* Subject Filter Pills */}
        <div className="flex flex-wrap gap-2 items-center">
          {subjects.map((sub) => (
            <button
              key={sub}
              onClick={() => setSelectedSubject(sub)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-smooth ${
                selectedSubject === sub
                  ? 'bg-slate-800 text-white border-slate-700'
                  : 'bg-transparent text-slate-400 border-slate-900 hover:border-slate-800'
              }`}
            >
              {sub}
            </button>
          ))}
        </div>
      </div>

      {/* DPP Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredDpps.length > 0 ? (
          filteredDpps.map((dpp) => {
            const attempt = attempts[dpp.id];
            const isCompleted = getDppStatus(dpp.id) === 'COMPLETED';
            const isInProgress = getDppStatus(dpp.id) === 'IN_PROGRESS';
            
            return (
              <div key={dpp.id} className="glass-card rounded-2xl p-6 flex flex-col justify-between h-64">
                <div className="space-y-4">
                  {/* Subject and Batch info */}
                  <div className="flex items-center justify-between">
                    <span className={`px-2.5 py-1 rounded-md text-xs font-semibold border ${getSubjectColor(dpp.subject)}`}>
                      {dpp.subject}
                    </span>
                    <span className="text-[11px] text-slate-500 font-mono">
                      Batch: {dpp.batch}
                    </span>
                  </div>

                  {/* Title & Topic info */}
                  <div className="space-y-1">
                    <h3 className="font-bold text-lg text-slate-100 line-clamp-2 leading-tight">
                      {dpp.name}
                    </h3>
                    <p className="text-xs text-slate-500 flex items-center gap-1">
                      <Clock size={12} />
                      <span>Est. time: {dpp.estimatedTime} mins</span>
                    </p>
                  </div>
                </div>

                {/* Footer and Call to Action buttons */}
                <div className="border-t border-slate-800/80 pt-4 flex items-center justify-between mt-auto">
                  <div className="text-xs text-slate-500">
                    <div>{dpp.totalQuestions} Questions</div>
                    {dpp.dueDate && (
                      <div className="text-[10px] mt-0.5 text-slate-600">Due: {dpp.dueDate}</div>
                    )}
                  </div>

                  {isCompleted ? (
                    <div className="flex items-center gap-2">
                      <span className="text-indigo-400 font-bold text-base mr-1">
                        {attempt?.score !== undefined ? `${attempt.score.toFixed(0)}%` : 'Graded'}
                      </span>
                      <button
                        onClick={() => onReviewDpp(dpp)}
                        className="bg-indigo-600/10 hover:bg-indigo-600/25 border border-indigo-500/20 text-indigo-400 px-4 py-2 rounded-xl text-xs font-bold transition-smooth flex items-center gap-1.5"
                      >
                        <span>Review</span>
                        <ArrowRight size={14} />
                      </button>
                    </div>
                  ) : isInProgress ? (
                    <button
                      onClick={() => onStartDpp(dpp)}
                      className="bg-orange-600 hover:bg-orange-500 text-white px-4 py-2 rounded-xl text-xs font-bold transition-smooth flex items-center gap-1.5 shadow-lg shadow-orange-950/20"
                    >
                      <Play size={12} className="fill-white" />
                      <span>Resume</span>
                    </button>
                  ) : (
                    <button
                      onClick={() => onStartDpp(dpp)}
                      className="bg-indigo-600 hover:bg-indigo-500 text-white px-4 py-2 rounded-xl text-xs font-bold transition-smooth flex items-center gap-1.5 shadow-lg shadow-indigo-950/20"
                    >
                      <BookOpen size={12} />
                      <span>Start Test</span>
                    </button>
                  )}
                </div>
              </div>
            );
          })
        ) : (
          <div className="col-span-full py-16 text-center space-y-3">
            <div className="w-16 h-16 rounded-full bg-slate-900 border border-slate-800 flex items-center justify-center text-slate-600 mx-auto">
              <CheckCircle size={28} />
            </div>
            <div className="space-y-1">
              <h3 className="font-bold text-slate-300 text-base">No DPPs available</h3>
              <p className="text-xs text-slate-500 max-w-xs mx-auto">
                There are no practice papers assigned for {selectedSubject} under this status tab.
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
