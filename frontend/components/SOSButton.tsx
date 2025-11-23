'use client'

import { useState } from 'react'
import { useAccount, useConnect, useDisconnect, useSendTransaction, useWaitForTransactionReceipt } from 'wagmi'
import { parseEther } from 'viem'

export function SOSButton() {
  const { address, isConnected } = useAccount()
  const { connect, connectors } = useConnect()
  const { disconnect } = useDisconnect()
  const [showModal, setShowModal] = useState(false)
  const [isProcessing, setIsProcessing] = useState(false)

  const { 
    sendTransaction, 
    data: hash,
    isPending: isPendingTx,
    error: txError 
  } = useSendTransaction()

  const { isLoading: isConfirming, isSuccess: isConfirmed } = 
    useWaitForTransactionReceipt({
      hash,
    })

  const handleSOSClick = async () => {
    if (!isConnected) {
      setShowModal(true)
      return
    }

    if (!address) return

    try {
      setIsProcessing(true)
      // Self transfer of 0 ETH (just a transaction to trigger SOS)
      await sendTransaction({
        to: address,
        value: parseEther('0'),
      })
    } catch (error) {
      console.error('SOS transaction failed:', error)
    } finally {
      setIsProcessing(false)
    }
  }

  const handleConnect = (connector: any) => {
    connect({ connector })
    setShowModal(false)
  }

  return (
    <>
      <div className="flex flex-col items-center justify-center min-h-screen">
        <button
          onClick={handleSOSClick}
          disabled={isPendingTx || isConfirming || isProcessing}
          className="relative group"
        >
          {/* Glowing background effect */}
          <div className="absolute inset-0 bg-[#00ff00] blur-xl opacity-50 group-hover:opacity-75 transition-opacity animate-pulse" />
          
          {/* Main button */}
          <div className="relative bg-black border border-[#00ff00] px-40 py-20 transform transition-all duration-300 hover:scale-105 hover:shadow-[0_0_60px_#00ff00] group-hover:animate-[glitch_0.3s_infinite]">
            <span className="text-8xl font-bold text-[#00ff00] tracking-wider font-mono relative group-hover:animate-[glitch-text_0.3s_infinite]">
              <span className="absolute inset-0 text-[#00ff00] blur-sm opacity-50">SOS</span>
              <span className="relative">SOS</span>
            </span>
            {/* Terminal-style corner brackets */}
            <div className="absolute top-2 left-2 text-[#00ff00] font-mono text-sm opacity-60">&lt;</div>
            <div className="absolute top-2 right-2 text-[#00ff00] font-mono text-sm opacity-60">&gt;</div>
            <div className="absolute bottom-2 left-2 text-[#00ff00] font-mono text-sm opacity-60">&lt;</div>
            <div className="absolute bottom-2 right-2 text-[#00ff00] font-mono text-sm opacity-60">&gt;</div>
            {/* Scan line effect */}
            <div className="absolute inset-0 bg-gradient-to-b from-transparent via-[#00ff00]/5 to-transparent animate-pulse pointer-events-none" style={{ animationDuration: '2s' }} />
          </div>
          
          {/* Status text */}
          {(isPendingTx || isConfirming) && (
            <p className="mt-6 text-[#00ff00] text-lg font-mono animate-pulse">
              Processing...
            </p>
          )}
          {isConfirmed && (
            <p className="mt-6 text-[#00ff00] text-lg font-mono">
              ✓ SOS Sent!
            </p>
          )}
          {txError && (
            <p className="mt-6 text-red-500 text-lg font-mono">
              ✗ Error: {txError.message}
            </p>
          )}
        </button>

        {/* Wallet address display */}
        {isConnected && address && (
          <div className="mt-8 px-6 py-3 bg-black/50 border border-[#00ff00]">
            <p className="text-[#00ff00] font-mono text-sm">
              {address.slice(0, 6)}...{address.slice(-4)}
            </p>
            <button
              onClick={() => disconnect()}
              className="mt-2 text-red-400 text-xs font-mono hover:text-red-300"
            >
              Disconnect
            </button>
          </div>
        )}
      </div>

      {/* Wallet Connect Modal */}
      {showModal && (
        <div 
          className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center"
          onClick={() => setShowModal(false)}
        >
          <div 
            className="bg-black border border-[#00ff00] p-8 max-w-md w-full mx-4 shadow-[0_0_40px_#00ff00]"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-2xl font-bold text-[#00ff00] font-mono mb-6 text-center">
              CONNECT WALLET
            </h2>
            
            <div className="space-y-3">
              {connectors.map((connector) => (
                <button
                  key={connector.id}
                  onClick={() => handleConnect(connector)}
                  className="w-full bg-black border border-[#00ff00] px-6 py-4 text-[#00ff00] font-mono hover:bg-[#00ff00]/10 hover:shadow-[0_0_20px_#00ff00] transition-all duration-300 text-left"
                >
                  <div className="flex items-center justify-between">
                    <span className="font-bold">{connector.name}</span>
                    <span className="text-sm">→</span>
                  </div>
                </button>
              ))}
            </div>

            <button
              onClick={() => setShowModal(false)}
              className="mt-6 w-full bg-red-900/30 border border-red-500 px-6 py-3 text-red-400 font-mono hover:bg-red-900/50 transition-all"
            >
              CANCEL
            </button>
          </div>
        </div>
      )}
    </>
  )
}

