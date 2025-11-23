import { SOSButton } from "../components/SOSButton";
import { MatrixRain } from "../components/MatrixRain";
import { TerminalText } from "../components/TerminalText";

export default function Home() {
  return (
    <main className="min-h-screen bg-black relative overflow-hidden">
      {/* Matrix rain effect */}
      <MatrixRain />
      
      {/* Terminal text scrolling */}
      <TerminalText />
      
      {/* Animated background elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-[#00ff00] opacity-5 blur-3xl animate-pulse" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-[#00ff00] opacity-5 blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
      </div>
      
      {/* Terminal-style code snippets */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-5">
        <pre className="absolute top-20 left-10 font-mono text-[#00ff00] text-xs">
{`function emergencyProtocol() {
  const chain = "Zircuit";
  const status = "ACTIVE";
  return { chain, status };
}`}
        </pre>
        <pre className="absolute bottom-20 right-10 font-mono text-[#00ff00] text-xs">
{`> LayerZero V2
> Endpoint: 0x6F47...
> Status: CONNECTED
> Ready for SOS`}
        </pre>
      </div>

      {/* Header */}
      <header className="absolute top-0 left-0 right-0 p-6 z-10">
        <div className="max-w-7xl mx-auto flex justify-between items-center">
          <h1 className="text-2xl font-bold text-[#00ff00] font-mono tracking-wider">
            SOS NOT SUS
          </h1>
          <div className="text-sm text-[#00ff00]/70 font-mono">
            EMERGENCY PROTOCOL
          </div>
        </div>
      </header>

      {/* Main content */}
      <div className="relative z-10">
        <SOSButton />
      </div>

      {/* Footer */}
      <footer className="absolute bottom-0 left-0 right-0 p-6 z-10">
        <div className="max-w-7xl mx-auto text-center">
          <p className="text-xs text-[#00ff00]/50 font-mono">
            CROSS-CHAIN RESCUE SYSTEM
          </p>
        </div>
      </footer>
    </main>
  );
}
