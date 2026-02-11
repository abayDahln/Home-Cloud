/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                primary: {
                    DEFAULT: '#2563EB', // Blue 600 - Vibrant and accessible
                    dark1: '#1D4ED8',   // Blue 700
                    dark2: '#1E40AF',   // Blue 800
                    dark3: '#1E3A8A',   // Blue 900
                    light1: '#3B82F6',  // Blue 500
                    light2: '#60A5FA',  // Blue 400
                    light3: '#93C5FD',  // Blue 300
                },
                textBlack: '#0F172A',   // Slate 900 - Richer than pure black
                gray: {
                    DEFAULT: '#64748B', // Slate 500 - Sophisticated neutral
                    light: '#94A3B8',   // Slate 400
                    dark: '#475569',    // Slate 600
                },
                lightGray: '#E2E8F0',   // Slate 200 - Cool neutral border
                bgWhite: '#F8FAFC',     // Slate 50 - Premium off-white
                darkBg: '#020617',      // Slate 950 - Deep dark mode background
            },
            fontFamily: {
                sans: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
            },
            animation: {
                'blob': 'blob 7s infinite',
                'float': 'float 6s ease-in-out infinite',
                'shimmer': 'shimmer 2.5s linear infinite',
                'pulse-glow': 'pulse-glow 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                'spin-slow': 'spin 8s linear infinite',
                'particle': 'particle 20s linear infinite',
                'liquid-pulse': 'liquid-pulse 4s ease-in-out infinite',
                'magnetic-pull': 'magnetic-pull 0.3s ease-out',
                'crystallize': 'crystallize 0.6s ease-out',
                'quantum-tunnel': 'quantum-tunnel 0.8s ease-out',
                'ripple': 'ripple 1.5s ease-out',
                'data-stream': 'data-stream 0.5s ease-out',
                'glitch': 'glitch 0.3s ease-in-out',
            },
            keyframes: {
                blob: {
                    '0%': { transform: 'translate(0px, 0px) scale(1)' },
                    '33%': { transform: 'translate(30px, -50px) scale(1.1)' },
                    '66%': { transform: 'translate(-20px, 20px) scale(0.9)' },
                    '100%': { transform: 'translate(0px, 0px) scale(1)' },
                },
                float: {
                    '0%, 100%': { transform: 'translateY(0)' },
                    '50%': { transform: 'translateY(-20px)' },
                },
                shimmer: {
                    '0%': { backgroundPosition: '-1000px 0' },
                    '100%': { backgroundPosition: '1000px 0' },
                },
                'pulse-glow': {
                    '0%, 100%': { opacity: '1', transform: 'scale(1)' },
                    '50%': { opacity: '0.8', transform: 'scale(1.05)' },
                },
                particle: {
                    '0%': { transform: 'translate(0, 0) rotate(0deg)', opacity: '0.3' },
                    '50%': { opacity: '0.6' },
                    '100%': { transform: 'translate(var(--tw-translate-x), var(--tw-translate-y)) rotate(360deg)', opacity: '0.3' },
                },
                'liquid-pulse': {
                    '0%, 100%': { borderRadius: '30% 70% 70% 30% / 30% 30% 70% 70%' },
                    '25%': { borderRadius: '58% 42% 75% 25% / 76% 46% 54% 24%' },
                    '50%': { borderRadius: '50% 50% 33% 67% / 55% 27% 73% 45%' },
                    '75%': { borderRadius: '33% 67% 58% 42% / 63% 68% 32% 37%' },
                },
                'magnetic-pull': {
                    '0%': { transform: 'scale(1) translateY(0)' },
                    '50%': { transform: 'scale(1.05) translateY(-8px)' },
                    '100%': { transform: 'scale(1.08) translateY(-12px)' },
                },
                crystallize: {
                    '0%': { transform: 'scale(1) rotate(0deg)', filter: 'brightness(1)' },
                    '50%': { transform: 'scale(1.2) rotate(180deg)', filter: 'brightness(1.5) drop-shadow(0 0 20px rgba(37, 99, 235, 0.8))' },
                    '100%': { transform: 'scale(1) rotate(360deg)', filter: 'brightness(1)' },
                },
                'quantum-tunnel': {
                    '0%': { transform: 'scale(1)', opacity: '1' },
                    '50%': { transform: 'scale(0.1)', opacity: '0.5' },
                    '100%': { transform: 'scale(1)', opacity: '1' },
                },
                ripple: {
                    '0%': { transform: 'scale(0)', opacity: '0.6' },
                    '100%': { transform: 'scale(4)', opacity: '0' },
                },
                'data-stream': {
                    '0%': { transform: 'translateX(-100px)', opacity: '0', filter: 'blur(4px)' },
                    '50%': { filter: 'blur(0px)' },
                    '100%': { transform: 'translateX(0)', opacity: '1', filter: 'blur(0px)' },
                },
                glitch: {
                    '0%, 100%': { transform: 'translate(0)' },
                    '20%': { transform: 'translate(-2px, 2px)' },
                    '40%': { transform: 'translate(-2px, -2px)' },
                    '60%': { transform: 'translate(2px, 2px)' },
                    '80%': { transform: 'translate(2px, -2px)' },
                },
            },
        },
    },
    plugins: [],
}
