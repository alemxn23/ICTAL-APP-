/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
        "./components/**/*.{js,ts,jsx,tsx}",
        "./App.tsx",
        "./index.tsx"
    ],
    theme: {
        extend: {
            colors: {
                'med-black': '#050505',
                'med-dark': '#0a0a0a',
                'med-green': '#39FF14', // Safe / Stable
                'med-amber': '#FFBF00', // Warning / Aura
                'med-red': '#FF003C',   // Critical / Status
                'med-blue': '#00F0FF',  // Info / Data
                'med-calm-blue': '#00C2FF', // Recovery / Post-Ictal
                'med-gray': '#2A2A2A',
                'med-coral': '#ff8a80', // Kept from previous guess just in case
                'med-teal': '#009688', // Added for completeness
            },
            fontFamily: {
                sans: ['system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'sans-serif'],
                mono: ['ui-monospace', 'SFMono-Regular', 'Menlo', 'Monaco', 'Consolas', "Liberation Mono", "Courier New", 'monospace'],
            },
            animation: {
                'pulse-fast': 'pulse 1s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                'flash-red': 'flashRed 1.5s infinite',
            },
            keyframes: {
                flashRed: {
                    '0%, 100%': { backgroundColor: '#050505' },
                    '50%': { backgroundColor: '#33000c' },
                }
            }
        },
    },
    plugins: [],
}
