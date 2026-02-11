import { Link } from 'react-router-dom'
import { useLanguage } from '../context/LanguageContext'
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion'
import { useRef, useState } from 'react'

const Landing = () => {
    const { t } = useLanguage()
    const heroRef = useRef(null)
    const [activePreview, setActivePreview] = useState('files') // 'files' | 'server' | 'login'
    const [previewFiles, setPreviewFiles] = useState([
        { name: 'foto', icon: 'folder' },
        { name: 'music', icon: 'folder' },
        { name: 'video', icon: 'folder' },
        { name: 'documents', icon: 'folder' },
    ])
    const [currentPath, setCurrentPath] = useState([])
    const [selectedFile, setSelectedFile] = useState(null)
    const [isPlaying, setIsPlaying] = useState(false)
    const [isInteracting, setIsInteracting] = useState(false)
    const [showPassword, setShowPassword] = useState(false)

    const { scrollYProgress } = useScroll({
        target: heroRef,
        offset: ['start start', 'end start'],
    })
    const heroY = useTransform(scrollYProgress, [0, 1], [0, 150])

    const features = [
        {
            icon: (
                <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
            ),
            title: t.features.secureStorage,
            description: t.features.secureStorageDesc,
            gradient: 'from-blue-500 to-indigo-600',
        },
        {
            icon: (
                <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
            ),
            title: t.features.multiPlatform,
            description: t.features.multiPlatformDesc,
            gradient: 'from-violet-500 to-purple-600',
        },
        {
            icon: (
                <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
            ),
            title: t.features.autoSync,
            description: t.features.autoSyncDesc,
            gradient: 'from-cyan-500 to-blue-600',
        },
        {
            icon: (
                <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
            ),
            title: t.features.fastReliable,
            description: t.features.fastReliableDesc,
            gradient: 'from-amber-500 to-orange-600',
        },
        {
            icon: (
                <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
            ),
            title: t.features.serverMonitoring,
            description: t.features.serverMonitoringDesc,
            gradient: 'from-emerald-500 to-teal-600',
        },
        {
            icon: (
                <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
            ),
            title: t.features.freeOpen,
            description: t.features.freeOpenDesc,
            gradient: 'from-rose-500 to-pink-600',
        },
    ]

    const platforms = [
        { name: 'Android', icon: '🤖', color: 'from-green-400 to-green-600' },
        { name: 'iOS', icon: '🍎', color: 'from-gray-400 to-gray-600' },
        { name: 'Windows', icon: '🪟', color: 'from-blue-400 to-blue-600' },
        { name: 'Linux', icon: '🐧', color: 'from-amber-400 to-amber-600' },
    ]

    // animation variants
    const fadeUp = {
        hidden: { opacity: 0, y: 40 },
        visible: (i = 0) => ({
            opacity: 1,
            y: 0,
            transition: { duration: 0.6, delay: i * 0.1, ease: 'easeOut' },
        }),
    }

    return (
        <div className="overflow-hidden">
            {/* ─────────────── HERO ─────────────── */}
            <section ref={heroRef} className="relative min-h-screen flex flex-col items-center justify-center pt-32 pb-20 px-4 lg:px-6 overflow-hidden">
                {/* Animated gradient background */}
                <div className="absolute inset-0 bg-gradient-to-br from-bgWhite via-white to-primary/5" />

                {/* Floating orbs */}
                <motion.div
                    animate={{ x: [0, 30, 0], y: [0, -20, 0] }}
                    transition={{ duration: 8, repeat: Infinity, ease: 'easeInOut' }}
                    className="absolute top-20 left-[10%] w-72 h-72 bg-primary/10 rounded-full blur-[100px]"
                />
                <motion.div
                    animate={{ x: [0, -40, 0], y: [0, 30, 0] }}
                    transition={{ duration: 10, repeat: Infinity, ease: 'easeInOut' }}
                    className="absolute bottom-20 right-[10%] w-96 h-96 bg-primary-light2/10 rounded-full blur-[120px]"
                />

                <motion.div
                    style={{ y: heroY }}
                    className="relative max-w-screen-2xl w-full mx-auto z-10 flex flex-col items-center"
                >
                    {/* Hero Text */}
                    <div className="text-center max-w-4xl mx-auto mb-16">
                        <motion.div
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.6 }}
                            className="inline-flex items-center gap-2 bg-primary/10 text-primary px-5 py-2 rounded-full text-sm font-semibold mb-6 border border-primary/20"
                        >
                            <span className="relative flex h-2 w-2">
                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                                <span className="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
                            </span>
                            {t.hero.version}
                        </motion.div>

                        <motion.h1
                            initial={{ opacity: 0, y: 30 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.7, delay: 0.1 }}
                            className="text-5xl md:text-7xl font-extrabold text-textBlack leading-[1.1] mb-6 tracking-tight"
                        >
                            {t.hero.title} <span className="gradient-text">{t.hero.titleHighlight}</span>
                        </motion.h1>

                        <motion.p
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.6, delay: 0.3 }}
                            className="text-lg md:text-xl text-gray leading-relaxed mb-10 max-w-2xl mx-auto"
                        >
                            {t.hero.description}
                        </motion.p>

                        <motion.div
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.6, delay: 0.45 }}
                            className="flex flex-col sm:flex-row gap-4 justify-center"
                        >
                            <Link
                                to="/download"
                                className="relative inline-flex items-center justify-center gap-2 bg-primary text-white font-bold py-4 px-10 rounded-2xl transition-all duration-300 shadow-lg shadow-primary/30 overflow-hidden group"
                            >
                                <span className="absolute inset-0 bg-primary-dark1 translate-y-full group-hover:translate-y-0 transition-transform duration-500 ease-out rounded-2xl" />
                                <svg className="w-5 h-5 relative z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                                </svg>
                                <span className="relative z-10">{t.hero.downloadFree}</span>
                            </Link>
                            <Link
                                to="/about"
                                className="inline-flex items-center justify-center gap-2 bg-white text-textBlack font-semibold py-4 px-10 rounded-2xl border border-lightGray hover:border-primary/30 hover:shadow-lg transition-all duration-300 group"
                            >
                                {t.hero.learnMore}
                                <svg className="w-4 h-4 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                                </svg>
                            </Link>
                        </motion.div>
                    </div>

                    {/* Interactive App Preview */}
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 40 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.4 }}
                        onMouseEnter={() => setIsInteracting(true)}
                        onMouseLeave={() => setIsInteracting(false)}
                        onFocus={() => setIsInteracting(true)}
                        onBlur={() => setIsInteracting(false)}
                        style={{ filter: 'none' }}
                        className="w-full max-w-5xl relative perspective-1000 z-20 focus:outline-none"
                        tabIndex="0"
                    >
                        {/* Glow effect */}
                        <div className="absolute -inset-10 bg-gradient-to-tr from-primary/20 via-primary-light2/10 to-primary-light3/10 rounded-[3rem] blur-3xl opacity-40" />

                        {/* App Container */}
                        <div className="relative bg-white rounded-2xl shadow-2xl shadow-primary/10 overflow-hidden border border-lightGray/60 flex h-[500px] md:h-[600px]">
                            {/* ─── Sidebar ─── */}
                            <div className="w-20 md:w-64 bg-bgWhite border-r border-lightGray flex flex-col flex-shrink-0 transition-all duration-300">
                                {/* Logo Area */}
                                <div className="h-16 flex items-center px-4 md:px-6 border-b border-lightGray/50">
                                    <div className="w-9 h-9 bg-gradient-to-br from-primary to-primary-dark1 rounded-xl flex items-center justify-center flex-shrink-0 shadow-lg shadow-primary/20">
                                        <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z" />
                                        </svg>
                                    </div>
                                    <span className="hidden md:block ml-3 font-bold text-textBlack text-lg tracking-tight">Home Cloud</span>
                                </div>

                                {/* Nav Items */}
                                <div className="flex-1 py-6 px-3 space-y-2">
                                    <div
                                        className={`flex items-center gap-3 px-3 py-2.5 rounded-xl font-medium cursor-pointer transition-all duration-200 ${activePreview === 'files' ? 'bg-primary text-white shadow-lg shadow-primary/30' : 'text-gray hover:bg-lightGray/50'}`}
                                        onClick={() => { setActivePreview('files'); setCurrentPath([]); }}
                                    >
                                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" /></svg>
                                        <span className="hidden md:block">All Files</span>
                                    </div>
                                    <div className="flex items-center gap-3 px-3 py-2.5 text-gray hover:bg-lightGray/50 rounded-xl font-medium transition-colors cursor-pointer">
                                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" /></svg>
                                        <span className="hidden md:block">Auto Backup</span>
                                    </div>
                                </div>

                                {/* Storage Widget - Clickable to show Monitoring */}
                                <div className="p-4 border-t border-lightGray/50 hidden md:block">
                                    <motion.div
                                        whileHover={{ scale: 1.02, y: -2 }}
                                        whileTap={{ scale: 0.98 }}
                                        onClick={() => setActivePreview('server')}
                                        className={`p-4 rounded-2xl border transition-all duration-300 cursor-pointer ${activePreview === 'server' ? 'bg-primary/5 border-primary shadow-lg shadow-primary/10' : 'bg-white border-lightGray/60 shadow-sm hover:border-primary/40'}`}
                                    >
                                        <div className={`flex items-center gap-2 mb-3 font-bold text-sm ${activePreview === 'server' ? 'text-primary' : 'text-textBlack'}`}>
                                            <div className={`p-1.5 rounded-lg ${activePreview === 'server' ? 'bg-primary text-white' : 'bg-blue-50 text-primary'}`}>
                                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" /></svg>
                                            </div>
                                            Storage
                                            <svg className={`w-4 h-4 ml-auto transition-transform ${activePreview === 'server' ? 'rotate-90' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                                        </div>
                                        <div className="w-full bg-lightGray/50 rounded-full h-1.5 overflow-hidden mb-2">
                                            <motion.div
                                                initial={{ width: 0 }}
                                                animate={{ width: '78.8%' }}
                                                transition={{ duration: 1.5, delay: 1, ease: 'easeOut' }}
                                                className="h-full bg-gradient-to-r from-primary to-primary-light2 rounded-full"
                                            />
                                        </div>
                                        <div className="text-[10px] text-gray flex justify-between">
                                            <span>12.01 GB used</span>
                                            <span>78.8%</span>
                                        </div>
                                    </motion.div>

                                    <button
                                        onClick={() => {
                                            setActivePreview('login')
                                            setCurrentPath([])
                                        }}
                                        className="w-full mt-4 py-2.5 rounded-xl border border-red-100 text-red-500 text-sm font-semibold hover:bg-red-50 transition-colors flex items-center justify-center gap-2 group"
                                    >
                                        <svg className="w-4 h-4 group-hover:-translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
                                        Logout
                                    </button>
                                </div>
                            </div>

                            {/* ─── Main Content Area ─── */}
                            <div className="flex-1 flex flex-col bg-bgWhite overflow-hidden relative">
                                <AnimatePresence mode="wait">
                                    {activePreview === 'files' ? (
                                        <motion.div
                                            key="files"
                                            initial={{ opacity: 0, x: 20 }}
                                            animate={{ opacity: 1, x: 0 }}
                                            exit={{ opacity: 0, x: -20 }}
                                            transition={{ duration: 0.4 }}
                                            className="flex-1 flex flex-col h-full relative"
                                        >
                                            {/* Top Bar for Files */}
                                            <div className="h-16 border-b border-lightGray/50 flex items-center justify-between px-4 md:px-8 bg-white z-10">
                                                <div className="flex items-center gap-2 text-gray text-sm">
                                                    {currentPath.length > 0 ? (
                                                        <button
                                                            onClick={() => setCurrentPath([])}
                                                            className="p-1 hover:bg-lightGray/50 rounded-full mr-1 transition-colors"
                                                        >
                                                            <svg className="w-5 h-5 text-textBlack" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7" /></svg>
                                                        </button>
                                                    ) : (
                                                        <svg className="w-5 h-5 text-gray/60" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
                                                    )}

                                                    {currentPath.length > 0 ? (
                                                        <>
                                                            <button onClick={() => setCurrentPath([])} className="hover:text-primary transition-colors flex items-center gap-2">
                                                                <svg className="w-5 h-5 text-gray/60" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" /></svg>
                                                            </button>
                                                            <span className="text-gray/40">/</span>
                                                            <span className="text-textBlack font-medium">{currentPath[currentPath.length - 1]}</span>
                                                        </>
                                                    ) : (
                                                        <>
                                                            <span className="text-gray/40">/</span>
                                                            <span className="text-textBlack font-medium">All Files</span>
                                                        </>
                                                    )}
                                                </div>
                                                <div className="flex items-center gap-4">
                                                    <div className="hidden md:flex items-center bg-bgWhite px-3 py-1.5 rounded-lg border border-lightGray/60 w-64">
                                                        <svg className="w-4 h-4 text-gray/60 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
                                                        <span className="text-xs text-gray/50">Search...</span>
                                                    </div>
                                                    <button className="bg-primary hover:bg-primary-dark1 text-white text-xs font-bold py-2 px-4 rounded-lg shadow-sm transition-colors flex items-center gap-1.5">
                                                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" /></svg>
                                                        New
                                                    </button>
                                                </div>
                                            </div>

                                            {/* Files Grid */}
                                            <div className="flex-1 p-4 md:p-8 overflow-y-auto">
                                                <div className="flex flex-wrap gap-4 md:gap-6">
                                                    {currentPath.length === 0 ? (
                                                        // Root: Folders
                                                        previewFiles.map((file, i) => (
                                                            <motion.div
                                                                key={i}
                                                                initial={{ scale: 0.8, opacity: 0 }}
                                                                animate={{ scale: 1, opacity: 1 }}
                                                                transition={{ delay: i * 0.1, type: 'spring' }}
                                                                whileHover={{ y: -5, boxShadow: '0 10px 25px -5px rgba(0,0,0,0.1)' }}
                                                                onClick={() => {
                                                                    if (file.name === 'foto') setCurrentPath(['foto']);
                                                                    if (file.name === 'music') setCurrentPath(['music']);
                                                                    if (file.name === 'video') setCurrentPath(['video']);
                                                                }}
                                                                className="w-32 h-36 md:w-40 md:h-48 rounded-2xl border border-lightGray/40 hover:border-primary/20 bg-white flex flex-col items-center justify-center p-4 shadow-sm transition-all duration-300 cursor-pointer group"
                                                            >
                                                                <div className="w-16 h-14 bg-blue-100 rounded-lg flex items-center justify-center mb-3 group-hover:scale-110 transition-transform duration-300">
                                                                    <svg className="w-10 h-10 text-primary fill-current" viewBox="0 0 24 24">
                                                                        <path d="M19.5 21a3 3 0 003-3v-4.5a3 3 0 00-3-3h-15a3 3 0 00-3 3V18a3 3 0 003 3h15zM1.5 10.146V6a3 3 0 013-3h5.379a2.25 2.25 0 011.59.659l2.122 2.121c.14.141.331.22.53.22H19.5a3 3 0 013 3v1.146A4.483 4.483 0 0019.5 9h-15a4.483 4.483 0 00-3 1.146z" />
                                                                    </svg>
                                                                </div>
                                                                <span className="font-semibold text-textBlack text-sm">{file.name}</span>
                                                                <span className="text-[10px] text-gray mt-1">Folder</span>
                                                            </motion.div>
                                                        ))
                                                    ) : currentPath[0] === 'foto' ? (
                                                        // Inside 'foto' folder
                                                        <motion.div
                                                            initial={{ scale: 0.8, opacity: 0 }}
                                                            animate={{ scale: 1, opacity: 1 }}
                                                            transition={{ type: 'spring' }}
                                                            whileHover={{ y: -5, boxShadow: '0 10px 25px -5px rgba(0,0,0,0.1)' }}
                                                            onClick={() => setSelectedFile({ name: 'Zebra.png', type: 'image', size: '420.2 KB', url: 'https://images.unsplash.com/photo-1501706362039-c06b2d715385?w=800&q=80' })}
                                                            className="w-32 h-36 md:w-40 md:h-48 rounded-2xl border border-lightGray/40 hover:border-primary/20 bg-white flex flex-col items-center justify-center p-2 shadow-sm transition-all duration-300 cursor-pointer group relative overflow-hidden"
                                                        >
                                                            <div className="w-full h-full absolute inset-0 bg-black/0 group-hover:bg-black/5 transition-colors z-0" />
                                                            <img
                                                                src="https://images.unsplash.com/photo-1501706362039-c06b2d715385?w=300&q=80"
                                                                alt="Zebra"
                                                                className="w-24 h-24 object-cover rounded-xl mb-3 shadow-md group-hover:scale-105 transition-transform duration-300 z-10"
                                                            />
                                                            <span className="font-semibold text-textBlack text-sm z-10 relative">Zebra.png</span>
                                                            <span className="text-[10px] text-gray z-10 relative">420.2 KB</span>
                                                        </motion.div>
                                                    ) : currentPath[0] === 'music' ? (
                                                        // Inside 'music' folder
                                                        <motion.div
                                                            initial={{ scale: 0.8, opacity: 0 }}
                                                            animate={{ scale: 1, opacity: 1 }}
                                                            transition={{ type: 'spring' }}
                                                            whileHover={{ y: -5, boxShadow: '0 10px 25px -5px rgba(0,0,0,0.1)' }}
                                                            onClick={() => {
                                                                setSelectedFile({ name: 'Kota Ini Tak Sama Tanpamu.mp3', type: 'audio', size: '10.8 MB' });
                                                                setIsPlaying(true);
                                                            }}
                                                            className="w-40 h-48 rounded-2xl border border-lightGray/40 hover:border-primary/20 bg-white flex flex-col items-center justify-center p-4 shadow-sm transition-all duration-300 cursor-pointer group"
                                                        >
                                                            <div className="w-16 h-16 bg-gray/10 rounded-xl flex items-center justify-center mb-3 group-hover:bg-primary/10 group-hover:text-primary transition-colors duration-300">
                                                                <svg className="w-8 h-8 text-gray group-hover:text-primary transition-colors" fill="currentColor" viewBox="0 0 24 24">
                                                                    <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
                                                                </svg>
                                                            </div>
                                                            <span className="font-semibold text-textBlack text-xs text-center line-clamp-2">Kota Ini Tak Sama Tanpamu.mp3</span>
                                                            <span className="text-[10px] text-gray mt-1">10.8 MB</span>
                                                        </motion.div>
                                                    ) : currentPath[0] === 'video' ? (
                                                        // Inside 'video' folder
                                                        <motion.div
                                                            initial={{ scale: 0.8, opacity: 0 }}
                                                            animate={{ scale: 1, opacity: 1 }}
                                                            transition={{ type: 'spring' }}
                                                            whileHover={{ y: -5, boxShadow: '0 10px 25px -5px rgba(0,0,0,0.1)' }}
                                                            onClick={() => {
                                                                setSelectedFile({
                                                                    name: 'me at the zoo.mp4',
                                                                    type: 'video',
                                                                    size: '772.8 KB',
                                                                    url: '/src/assets/preview/me at the zoo.mp4'
                                                                });
                                                            }}
                                                            className="w-40 h-48 rounded-2xl border border-lightGray/40 hover:border-primary/20 bg-white flex flex-col items-center justify-center p-4 shadow-sm transition-all duration-300 cursor-pointer group"
                                                        >
                                                            <div className="w-16 h-16 bg-gray/10 rounded-xl flex items-center justify-center mb-3 group-hover:bg-primary/10 group-hover:text-primary transition-colors duration-300">
                                                                <svg className="w-8 h-8 text-gray group-hover:text-primary transition-colors" fill="currentColor" viewBox="0 0 24 24">
                                                                    <path d="M17 10.5V7c0-.55-.45-1-1-1H4c-.55 0-1 .45-1 1v10c0 .55.45 1 1 1h12c.55 0 1-.45 1-1v-3.5l4 4v-11l-4 4z" />
                                                                </svg>
                                                            </div>
                                                            <span className="font-semibold text-textBlack text-xs text-center line-clamp-2">me at the zoo.mp4</span>
                                                            <span className="text-[10px] text-gray mt-1">772.8 KB</span>
                                                        </motion.div>
                                                    ) : null}
                                                </div>
                                            </div>

                                            {/* File Detail Modal */}
                                            <AnimatePresence>
                                                {selectedFile && (
                                                    <motion.div
                                                        initial={{ opacity: 0 }}
                                                        animate={{ opacity: 1 }}
                                                        exit={{ opacity: 0 }}
                                                        className="absolute inset-0 z-50 flex items-center justify-center bg-black/80 p-4"
                                                        onClick={() => { setSelectedFile(null); setIsPlaying(false); }}
                                                    >
                                                        <motion.div
                                                            initial={{ scale: 0.9, opacity: 0 }}
                                                            animate={{ scale: 1, opacity: 1 }}
                                                            exit={{ scale: 0.9, opacity: 0 }}
                                                            onClick={(e) => e.stopPropagation()}
                                                            className={`${selectedFile.type === 'audio' ? 'bg-[#1A1A1A]' : 'bg-[#1a1c23]'} rounded-3xl shadow-2xl overflow-hidden max-w-sm w-full relative flex flex-col`}
                                                        >
                                                            {/* Close Button */}
                                                            <button
                                                                onClick={() => { setSelectedFile(null); setIsPlaying(false); }}
                                                                className="absolute top-4 right-4 p-2 rounded-full bg-white/10 hover:bg-white/20 text-white/70 hover:text-white transition-colors z-20"
                                                            >
                                                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                                                            </button>

                                                            {selectedFile.type === 'image' ? (
                                                                <>
                                                                    {/* Image Modal Content */}
                                                                    <div className="h-14 border-b border-white/10 flex items-center justify-between px-4 bg-[#1f222a]">
                                                                        <div className="flex items-center gap-2">
                                                                            <div className="w-8 h-8 rounded-lg bg-blue-500/20 flex items-center justify-center">
                                                                                <svg className="w-5 h-5 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                                                                            </div>
                                                                            <span className="text-white font-medium text-sm">{selectedFile.name}</span>
                                                                        </div>
                                                                    </div>
                                                                    <div className="flex-1 flex items-center justify-center bg-black/40 p-1 relative overflow-hidden group">
                                                                        <img
                                                                            src={selectedFile.url}
                                                                            alt={selectedFile.name}
                                                                            className="max-w-full max-h-[60vh] object-contain shadow-2xl"
                                                                        />
                                                                    </div>
                                                                    <div className="h-10 bg-[#1f222a] border-t border-white/10 flex items-center justify-center text-[10px] text-white/50">
                                                                        Pinch to zoom • 100%
                                                                    </div>
                                                                </>
                                                            ) : selectedFile.type === 'video' ? (
                                                                /* Video Player Content */
                                                                <div className="flex flex-col bg-[#0A0A0A]">
                                                                    {/* Header */}
                                                                    <div className="p-4 flex items-center justify-between">
                                                                        <div className="flex items-center gap-3">
                                                                            <div className="w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center">
                                                                                <svg className="w-5 h-5 text-blue-400" fill="currentColor" viewBox="0 0 24 24">
                                                                                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 14.5v-9l6 4.5-6 4.5z" />
                                                                                </svg>
                                                                            </div>
                                                                            <div className="flex flex-col text-left">
                                                                                <span className="text-white font-bold text-sm tracking-tight">{selectedFile.name}</span>
                                                                                <span className="text-white/40 text-[10px] font-medium">00:19</span>
                                                                            </div>
                                                                        </div>
                                                                    </div>

                                                                    {/* Video Viewport */}
                                                                    <div className="aspect-video bg-black flex items-center justify-center overflow-hidden">
                                                                        <video
                                                                            src={selectedFile.url}
                                                                            controls
                                                                            autoPlay
                                                                            className="w-full h-full object-contain"
                                                                        />
                                                                    </div>

                                                                    {/* Bottom Padding */}
                                                                    <div className="h-6" />
                                                                </div>
                                                            ) : (
                                                                /* Audio Player Content */
                                                                <div className="p-8 flex flex-col items-center text-center relative overflow-hidden">
                                                                    {/* Rotating Glow Background */}
                                                                    {isPlaying && (
                                                                        <motion.div
                                                                            animate={{ rotate: 360 }}
                                                                            transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
                                                                            className="absolute top-1/4 left-1/2 -translate-x-1/2 w-64 h-64 bg-gradient-to-tr from-primary/20 via-primary-light2/10 to-transparent rounded-full blur-3xl pointer-events-none"
                                                                        />
                                                                    )}

                                                                    {/* Album Art */}
                                                                    <div className="relative mb-8 mt-4">
                                                                        <motion.div
                                                                            animate={isPlaying ? { scale: [1, 1.02, 1] } : { scale: 1 }}
                                                                            transition={{ duration: 2, repeat: Infinity }}
                                                                            className="w-40 h-40 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-3xl shadow-2xl shadow-blue-500/20 flex items-center justify-center relative z-10"
                                                                        >
                                                                            <svg className="w-16 h-16 text-white" fill="currentColor" viewBox="0 0 24 24">
                                                                                <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z" />
                                                                            </svg>
                                                                        </motion.div>
                                                                    </div>

                                                                    {/* File Info */}
                                                                    <h3 className="text-white font-bold text-lg mb-1 line-clamp-1 w-full">{selectedFile.name}</h3>
                                                                    <p className="text-white/50 text-xs font-medium mb-8">Audio File</p>

                                                                    {/* Waveform Visualization */}
                                                                    <div className="h-12 flex items-center justify-center gap-1 mb-8 w-full">
                                                                        {[...Array(20)].map((_, i) => (
                                                                            <motion.div
                                                                                key={i}
                                                                                animate={isPlaying ? {
                                                                                    height: [10, Math.random() * 40 + 10, 10],
                                                                                } : { height: 6 }}
                                                                                transition={{
                                                                                    duration: 0.5,
                                                                                    repeat: Infinity,
                                                                                    delay: i * 0.05,
                                                                                    ease: "easeInOut"
                                                                                }}
                                                                                className="w-1 bg-gradient-to-t from-blue-500 to-indigo-400 rounded-full opacity-80"
                                                                            />
                                                                        ))}
                                                                    </div>

                                                                    {/* Progress Bar (Static) */}
                                                                    <div className="w-full mb-2">
                                                                        <div className="h-1 bg-white/10 rounded-full overflow-hidden">
                                                                            <div className="h-full w-1/3 bg-blue-500 rounded-full relative">
                                                                                <div className="absolute right-0 top-1/2 -translate-y-1/2 w-3 h-3 bg-blue-400 rounded-full shadow-lg transform translate-x-1" />
                                                                            </div>
                                                                        </div>
                                                                        <div className="flex justify-between text-[10px] text-white/40 mt-2 font-medium">
                                                                            <span>00:03</span>
                                                                            <span>04:39</span>
                                                                        </div>
                                                                    </div>

                                                                    {/* Controls */}
                                                                    <div className="flex items-center justify-center gap-6 mt-4">
                                                                        <button className="text-white/40 hover:text-white transition-colors">
                                                                            <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M6 6h2v12H6zm3.5 6l8.5 6V6z" /></svg>
                                                                        </button>
                                                                        <button className="text-white/70 hover:text-white transition-colors">
                                                                            <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M12 5V1L7 6l5 5V7c3.31 0 6 2.69 6 6s-2.69 6-6 6-6-2.69-6-6H4c0 4.42 3.58 8 8 8s8-3.58 8-8-3.58-8-8-8zm-1.1 11h2.2v-2.2h-2.2v2.2zm0-4.4h2.2v-4h-2.2v4z" /></svg>
                                                                        </button>
                                                                        <button
                                                                            onClick={() => setIsPlaying(!isPlaying)}
                                                                            className="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center shadow-lg shadow-blue-500/30 hover:scale-105 active:scale-95 transition-all text-white"
                                                                        >
                                                                            {isPlaying ? (
                                                                                <svg className="w-7 h-7" fill="currentColor" viewBox="0 0 24 24"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" /></svg>
                                                                            ) : (
                                                                                <svg className="w-7 h-7 translate-x-0.5" fill="currentColor" viewBox="0 0 24 24"><path d="M8 5v14l11-7z" /></svg>
                                                                            )}
                                                                        </button>
                                                                        <button className="text-white/70 hover:text-white transition-colors">
                                                                            <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M12 5V1l5 5-5 5V7c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6h2c0 4.42-3.58 8-8 8s-8-3.58-8-8 3.58-8 8-8zm1.1 11h-2.2v-2.2h2.2v2.2zm0-4.4h-2.2v-4h2.2v4z" /></svg>
                                                                        </button>
                                                                        <button className="text-white/40 hover:text-white transition-colors">
                                                                            <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z" /></svg>
                                                                        </button>
                                                                    </div>
                                                                </div>
                                                            )}
                                                        </motion.div>
                                                    </motion.div>
                                                )}
                                            </AnimatePresence>

                                        </motion.div>
                                    ) : (
                                        <motion.div
                                            key="login"
                                            initial={{ opacity: 0, scale: 0.9 }}
                                            animate={{ opacity: 1, scale: 1 }}
                                            exit={{ opacity: 0, scale: 0.9 }}
                                            transition={{ duration: 0.4 }}
                                            className="flex-1 flex flex-col items-center justify-center p-6 bg-white"
                                        >
                                            <div className="w-full max-w-sm flex flex-col items-center">
                                                {/* Login Logo */}
                                                <div className="mb-8 flex flex-col items-center">
                                                    <div className="w-20 h-20 bg-primary/10 rounded-3xl flex items-center justify-center mb-6 shadow-xl shadow-primary/5">
                                                        <svg className="w-12 h-12 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z" />
                                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 13.5V11a3 3 0 016 0v2.5M9 13.5h6" />
                                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3L4 9v12h16V9l-8-6z" />
                                                        </svg>
                                                    </div>
                                                    <h2 className="text-3xl font-bold text-textBlack mb-2">Home Cloud</h2>
                                                    <p className="text-gray text-sm">Connect to your personal server</p>
                                                </div>

                                                {/* Login Form Inputs */}
                                                <div className="w-full space-y-4 mb-8">
                                                    <div className="relative group">
                                                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-gray/50 group-focus-within:text-primary transition-colors">
                                                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                                                            </svg>
                                                        </div>
                                                        <input
                                                            type="text"
                                                            placeholder="Server URL"
                                                            className="w-full bg-bgWhite border border-lightGray/60 rounded-2xl py-4 pl-12 pr-4 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all font-medium"
                                                        />
                                                    </div>
                                                    <div className="relative group">
                                                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-gray/50 group-focus-within:text-primary transition-colors">
                                                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                                                            </svg>
                                                        </div>
                                                        <input
                                                            type={showPassword ? "text" : "password"}
                                                            placeholder="Password"
                                                            className="w-full bg-bgWhite border border-lightGray/60 rounded-2xl py-4 pl-12 pr-12 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all font-medium"
                                                        />
                                                        <button
                                                            onClick={() => setShowPassword(!showPassword)}
                                                            className="absolute inset-y-0 right-0 pr-4 flex items-center text-gray/50 hover:text-gray transition-colors"
                                                        >
                                                            {showPassword ? (
                                                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18" /></svg>
                                                            ) : (
                                                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                                                            )}
                                                        </button>
                                                    </div>
                                                </div>

                                                <button
                                                    onClick={() => {
                                                        setActivePreview('files')
                                                        setPreviewFiles(prev => prev.filter(f => f.name !== 'documents'))
                                                    }}
                                                    className="w-full bg-primary text-white font-bold py-4 rounded-2xl shadow-lg shadow-primary/25 hover:bg-primary-dark1 active:scale-[0.98] transition-all"
                                                >
                                                    Connect
                                                </button>
                                            </div>
                                        </motion.div>
                                    )}
                                </AnimatePresence>
                            </div>
                        </div>
                    </motion.div>
                </motion.div>
            </section>

            {/* ─────────────── FEATURES ─────────────── */}
            <section className="py-24 px-6 lg:px-8 bg-white relative">
                {/* Background decoration */}
                <div className="absolute inset-0 pointer-events-none overflow-hidden">
                    <div className="absolute -right-40 top-20 w-80 h-80 bg-primary/5 rounded-full blur-[100px]" />
                    <div className="absolute -left-40 bottom-20 w-80 h-80 bg-primary-light3/5 rounded-full blur-[100px]" />
                </div>

                <div className="max-w-screen-2xl mx-auto relative">
                    <motion.div
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true, margin: '-100px' }}
                        className="text-center mb-16"
                    >
                        <motion.h2
                            variants={fadeUp}
                            custom={0}
                            className="text-3xl md:text-5xl font-extrabold text-textBlack mb-4"
                        >
                            {t.features.title}
                        </motion.h2>
                        <motion.p
                            variants={fadeUp}
                            custom={1}
                            className="text-gray text-lg max-w-2xl mx-auto"
                        >
                            {t.features.description}
                        </motion.p>
                    </motion.div>

                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {features.map((feature, index) => (
                            <motion.div
                                key={index}
                                initial="hidden"
                                whileInView="visible"
                                viewport={{ once: true, margin: '-50px' }}
                                variants={fadeUp}
                                custom={index}
                                whileHover={{ y: -6, transition: { duration: 0.3 } }}
                                className="group relative p-7 rounded-2xl bg-white border border-lightGray/60 shadow-sm hover:shadow-xl hover:border-primary/20 transition-all duration-500"
                            >
                                {/* Hover gradient glow */}
                                <div className={`absolute inset-0 rounded-2xl bg-gradient-to-br ${feature.gradient} opacity-0 group-hover:opacity-[0.03] transition-opacity duration-500`} />
                                <div className="relative">
                                    <div className={`w-12 h-12 bg-gradient-to-br ${feature.gradient} text-white rounded-xl flex items-center justify-center mb-4 shadow-lg group-hover:scale-110 transition-transform duration-300`}>
                                        {feature.icon}
                                    </div>
                                    <h3 className="text-lg font-bold text-textBlack mb-2">{feature.title}</h3>
                                    <p className="text-gray text-sm leading-relaxed">{feature.description}</p>
                                </div>
                            </motion.div>
                        ))}
                    </div>
                </div>
            </section>

            {/* ─────────────── PLATFORMS ─────────────── */}
            <section className="py-24 px-6 lg:px-8 bg-bgWhite relative">
                <div className="max-w-screen-2xl mx-auto text-center">
                    <motion.h2
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        variants={fadeUp}
                        className="text-3xl md:text-5xl font-extrabold text-textBlack mb-4"
                    >
                        {t.platforms.title}
                    </motion.h2>
                    <motion.p
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        variants={fadeUp}
                        custom={1}
                        className="text-gray text-lg max-w-2xl mx-auto mb-14"
                    >
                        {t.platforms.description}
                    </motion.p>

                    <div className="flex flex-wrap justify-center gap-6">
                        {platforms.map((platform, index) => (
                            <motion.div
                                key={index}
                                initial="hidden"
                                whileInView="visible"
                                viewport={{ once: true }}
                                variants={fadeUp}
                                custom={index}
                                whileHover={{ y: -8, scale: 1.05, transition: { type: 'spring', stiffness: 300 } }}
                                className="bg-white rounded-2xl px-10 py-8 shadow-md hover:shadow-xl border border-lightGray/40 hover:border-primary/20 transition-all duration-300 cursor-default group"
                            >
                                <motion.span
                                    animate={{ scale: [1, 1.08, 1] }}
                                    transition={{ duration: 3, repeat: Infinity, ease: 'easeInOut', delay: index * 0.5 }}
                                    className="text-5xl mb-3 block"
                                >
                                    {platform.icon}
                                </motion.span>
                                <span className="font-bold text-textBlack group-hover:text-primary transition-colors duration-300">{platform.name}</span>
                            </motion.div>
                        ))}
                    </div>
                </div>
            </section>

            {/* ─────────────── CTA ─────────────── */}
            <section className="py-24 px-6 lg:px-8">
                <motion.div
                    initial="hidden"
                    whileInView="visible"
                    viewport={{ once: true }}
                    variants={fadeUp}
                    className="max-w-5xl mx-auto"
                >
                    <div className="relative bg-gradient-to-br from-primary via-primary-dark1 to-primary-dark2 rounded-3xl p-12 md:p-16 text-center text-white overflow-hidden">
                        {/* Decorative elements */}
                        <div className="absolute top-0 left-0 w-40 h-40 bg-white/10 rounded-full -translate-x-1/2 -translate-y-1/2" />
                        <div className="absolute bottom-0 right-0 w-60 h-60 bg-white/5 rounded-full translate-x-1/3 translate-y-1/3" />
                        <motion.div
                            animate={{ rotate: 360 }}
                            transition={{ duration: 60, repeat: Infinity, ease: 'linear' }}
                            className="absolute top-10 right-10 w-20 h-20 border border-white/10 rounded-full"
                        />

                        <div className="relative">
                            <h2 className="text-3xl md:text-5xl font-extrabold mb-4">
                                {t.cta.title}
                            </h2>
                            <p className="text-white/70 text-lg mb-10 max-w-lg mx-auto">
                                {t.cta.description}
                            </p>
                            <Link
                                to="/download"
                                className="inline-flex items-center gap-2 bg-white text-primary font-bold py-4 px-10 rounded-2xl hover:bg-bgWhite hover:shadow-2xl transition-all duration-300 group"
                            >
                                {t.cta.button}
                                <svg className="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                                </svg>
                            </Link>
                        </div>
                    </div>
                </motion.div>
            </section>
        </div>
    )
}

export default Landing
