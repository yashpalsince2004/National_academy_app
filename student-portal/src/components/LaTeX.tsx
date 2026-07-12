import React from 'react';
import katex from 'katex';

interface LaTeXProps {
  text: string;
  className?: string;
}

export const LaTeX: React.FC<LaTeXProps> = ({ text, className = '' }) => {
  if (!text) return null;

  // Split text by block math $$
  const parts = text.split(/(\$\$[\s\S]*?\$\$)/g);

  const renderedElements = parts.map((part, index) => {
    // If it's a block math segment
    if (part.startsWith('$$') && part.endsWith('$$')) {
      const math = part.slice(2, -2).trim();
      try {
        const html = katex.renderToString(math, {
          displayMode: true,
          throwOnError: false,
        });
        return (
          <div
            key={index}
            className="my-3 overflow-x-auto text-center"
            dangerouslySetInnerHTML={{ __html: html }}
          />
        );
      } catch (err) {
        console.error('KaTeX block error:', err);
        return <pre key={index} className="text-red-400">{part}</pre>;
      }
    }

    // Otherwise, parse inline math $ inside this plain text segment
    const subParts = part.split(/(\$.*?\$)/g);
    return (
      <span key={index}>
        {subParts.map((subPart, subIndex) => {
          if (subPart.startsWith('$') && subPart.endsWith('$')) {
            const math = subPart.slice(1, -1).trim();
            try {
              const html = katex.renderToString(math, {
                displayMode: false,
                throwOnError: false,
              });
              return (
                <span
                  key={subIndex}
                  className="inline-block px-0.5 align-middle"
                  dangerouslySetInnerHTML={{ __html: html }}
                />
              );
            } catch (err) {
              console.error('KaTeX inline error:', err);
              return <code key={subIndex} className="text-red-400">{subPart}</code>;
            }
          }
          return <React.Fragment key={subIndex}>{subPart}</React.Fragment>;
        })}
      </span>
    );
  });

  return <div className={`leading-relaxed whitespace-pre-line ${className}`}>{renderedElements}</div>;
};
