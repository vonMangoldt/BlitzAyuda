import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import fs from 'fs';

const execAsync = promisify(exec);

export async function POST() {
    try {
        console.log('Executing forge script...');

        // Just run the forge script from the frontend directory
        // Forge will find foundry.toml in parent and use that as root
        const command = `cd .. && forge script script/FinalTest.s.sol --broadcast`;

        const { stdout, stderr } = await execAsync(command);

        console.log('Forge stdout:', stdout);
        if (stderr) console.error('Forge stderr:', stderr);

        // Parse Transaction Hash from output
        let txHash = null;

        // Try multiple patterns to find transaction hash
        const patterns = [
            /transactionHash[:\s]+(?:"|')?(0x[a-fA-F0-9]{64})(?:"|')?/i,
            /Transaction[:\s]+(?:"|')?(0x[a-fA-F0-9]{64})(?:"|')?/i,
            /hash[:\s]+(?:"|')?(0x[a-fA-F0-9]{64})(?:"|')?/i,
        ];

        for (const pattern of patterns) {
            const match = stdout.match(pattern);
            if (match && match[1]) {
                txHash = match[1];
                console.log('Found transaction hash:', txHash);
                break;
            }
        }

        // If no hash found in stdout, try to read from broadcast file
        if (!txHash) {
            try {
                // Try the Zircuit broadcast file (chain ID 48900)
                const broadcastPath = path.join(process.cwd(), '..', 'broadcast', 'FinalTest.s.sol', '48900', 'run-latest.json');
                if (fs.existsSync(broadcastPath)) {
                    const broadcastData = JSON.parse(fs.readFileSync(broadcastPath, 'utf-8'));
                    // Look for the last transaction hash in the broadcast data
                    if (broadcastData.transactions && broadcastData.transactions.length > 0) {
                        const lastTx = broadcastData.transactions[broadcastData.transactions.length - 1];
                        txHash = lastTx.hash || lastTx.transactionHash;
                        console.log('Found transaction hash from broadcast file:', txHash);
                    }
                }
            } catch (e) {
                console.warn('Could not read broadcast file:', e);
            }
        }

        return NextResponse.json({
            success: true,
            output: stdout,
            txHash: txHash
        });

    } catch (error: any) {
        console.error('Script execution failed:', error);
        return NextResponse.json({
            success: false,
            error: error.message || 'Script execution failed',
            stderr: error.stderr,
            output: error.stdout
        }, { status: 500 });
    }
}

