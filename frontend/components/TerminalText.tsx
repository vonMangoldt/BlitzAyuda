'use client'

export function TerminalText() {
  const terminalLines = [
    '> INITIALIZING CROSS-CHAIN PROTOCOL...',
    '> CONNECTING TO LAYERZERO NETWORK...',
    '> SCANNING BLOCKCHAIN NODES...',
    '> ESTABLISHING SECURE CHANNEL...',
    '> READY FOR EMERGENCY TRANSMISSION',
    '> STATUS: STANDBY',
    '> AWAITING USER INPUT...',
  ]

  return (
    <>
      <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-10">
        {terminalLines.map((line, index) => (
          <div
            key={index}
            className="absolute font-mono text-[#00ff00] text-xs whitespace-nowrap terminal-scroll"
            style={{
              left: `${10 + index * 5}%`,
              top: `${15 + index * 8}%`,
              animation: `scrollRight ${20 + index * 2}s linear infinite`,
              animationDelay: `${index * 0.5}s`,
            }}
          >
            {line}
          </div>
        ))}
      </div>
      <style jsx global>{`
        @keyframes scrollRight {
          0% {
            transform: translateX(-100%);
            opacity: 0;
          }
          10% {
            opacity: 1;
          }
          90% {
            opacity: 1;
          }
          100% {
            transform: translateX(100vw);
            opacity: 0;
          }
        }
      `}</style>
    </>
  )
}

