import React, { useEffect, useRef } from 'react';
import { useOnboarding } from '../../context/OnboardingContext';
import { OnboardingStep } from '../../types';

/**
 * Phase 1 — Welcome Screen
 * Pure black hero with animated neural pulse, app logo, and dual CTA.
 */
export const WelcomeScreen: React.FC = () => {
    const { setStep } = useOnboarding();
    const canvasRef = useRef<HTMLCanvasElement>(null);

    // Animated neural network background
    useEffect(() => {
        const canvas = canvasRef.current;
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        if (!ctx) return;

        canvas.width = canvas.offsetWidth;
        canvas.height = canvas.offsetHeight;

        const nodes: { x: number; y: number; vx: number; vy: number }[] = [];
        const NODE_COUNT = 30;

        for (let i = 0; i < NODE_COUNT; i++) {
            nodes.push({
                x: Math.random() * canvas.width,
                y: Math.random() * canvas.height,
                vx: (Math.random() - 0.5) * 0.4,
                vy: (Math.random() - 0.5) * 0.4,
            });
        }

        let animId: number;
        const draw = () => {
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            // Draw connections
            for (let i = 0; i < nodes.length; i++) {
                for (let j = i + 1; j < nodes.length; j++) {
                    const dx = nodes[i].x - nodes[j].x;
                    const dy = nodes[i].y - nodes[j].y;
                    const dist = Math.sqrt(dx * dx + dy * dy);
                    if (dist < 120) {
                        const alpha = (1 - dist / 120) * 0.25;
                        ctx.beginPath();
                        ctx.strokeStyle = `rgba(0, 240, 255, ${alpha})`;
                        ctx.lineWidth = 0.6;
                        ctx.moveTo(nodes[i].x, nodes[i].y);
                        ctx.lineTo(nodes[j].x, nodes[j].y);
                        ctx.stroke();
                    }
                }
            }

            // Draw nodes
            nodes.forEach(node => {
                ctx.beginPath();
                ctx.arc(node.x, node.y, 1.5, 0, Math.PI * 2);
                ctx.fillStyle = 'rgba(0, 240, 255, 0.5)';
                ctx.fill();

                // Move
                node.x += node.vx;
                node.y += node.vy;
                if (node.x < 0 || node.x > canvas.width) node.vx *= -1;
                if (node.y < 0 || node.y > canvas.height) node.vy *= -1;
            });

            animId = requestAnimationFrame(draw);
        };

        draw();
        return () => cancelAnimationFrame(animId);
    }, []);

    return (
        <div className="relative w-full h-full bg-med-black flex flex-col items-center justify-between overflow-hidden">
            {/* Neural network canvas background */}
            <canvas
                ref={canvasRef}
                className="absolute inset-0 w-full h-full opacity-60"
            />

            {/* Top spacer */}
            <div className="flex-1" />

            {/* Logo + Tagline */}
            <div className="relative z-10 flex flex-col items-center px-8 text-center">
                {/* Animated brain icon */}
                <div className="relative mb-6">
                    <div className="w-24 h-24 rounded-full bg-med-blue/10 border border-med-blue/30 flex items-center justify-center">
                        <div className="w-16 h-16 rounded-full bg-med-blue/20 border border-med-blue/50 flex items-center justify-center animate-pulse">
                            <svg width="36" height="36" viewBox="0 0 36 36" fill="none">
                                {/* Simplified brain SVG */}
                                <ellipse cx="12" cy="16" rx="8" ry="10" stroke="#00F0FF" strokeWidth="1.5" fill="none" />
                                <ellipse cx="24" cy="16" rx="8" ry="10" stroke="#00F0FF" strokeWidth="1.5" fill="none" />
                                <line x1="18" y1="6" x2="18" y2="26" stroke="#00F0FF" strokeWidth="1" opacity="0.5" />
                                <circle cx="8" cy="12" r="1.5" fill="#00F0FF" opacity="0.7" />
                                <circle cx="28" cy="20" r="1.5" fill="#00F0FF" opacity="0.7" />
                                <circle cx="18" cy="18" r="2" fill="#00F0FF" opacity="0.9" />
                            </svg>
                        </div>
                    </div>
                    {/* Orbital ring */}
                    <div className="absolute inset-0 border border-med-blue/20 rounded-full animate-spin" style={{ animationDuration: '8s' }} />
                </div>

                <h1 className="text-3xl font-bold text-white mb-2 tracking-tight">
                    EpilepsyCare<span className="text-med-blue"> AI</span>
                </h1>

                <p className="text-base text-gray-400 mb-2 leading-snug">
                    Tu diario neurológico seguro
                </p>

                <p className="text-xs text-gray-600 leading-relaxed max-w-xs">
                    Monitoreo predictivo de crisis, medicación inteligente y coordinación de emergencias — todo en tu bolsillo.
                </p>
            </div>

            <div className="flex-1" />

            {/* CTA Buttons */}
            <div className="relative z-10 w-full px-8 pb-10 flex flex-col gap-3">
                {/* Primary — Sign Up */}
                <button
                    onClick={() => setStep(OnboardingStep.AUTH)}
                    className="w-full py-4 bg-med-blue text-black font-bold text-base rounded-2xl tracking-wide shadow-lg shadow-med-blue/30 active:scale-95 transition-transform"
                    style={{ letterSpacing: '0.03em' }}
                >
                    Crear Cuenta
                </button>

                {/* Ghost — Sign In */}
                <button
                    onClick={() => setStep(OnboardingStep.AUTH)}
                    className="w-full py-4 bg-transparent text-med-blue font-semibold text-base rounded-2xl border border-med-blue/40 tracking-wide active:scale-95 transition-transform"
                >
                    Ya tengo cuenta
                </button>

                <p className="text-center text-[10px] text-gray-600 mt-2 leading-relaxed">
                    Al continuar, aceptas cumplir con la legislación vigente de protección de datos sanitarios (HIPAA / NOM-024-SSA3).
                </p>
            </div>
        </div>
    );
};
