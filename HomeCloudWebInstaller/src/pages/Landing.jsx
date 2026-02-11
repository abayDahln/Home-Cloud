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
            gradient: 'from-primary to-primary-dark1',
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
            gradient: 'from-primary-light1 to-primary',
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
        {
            name: 'Android',
            icon: (
                <svg className="w-12 h-12" viewBox="0 0 24 24" fill="#3DDC84">
                    <path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9997.9993-.9997c.5511 0 .9993.4486.9993.9997s-.4482.9997-.9993.9997zm-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9997.9993-.9997c.5511 0 .9993.4486.9993.9997s-.4482.9997-.9993.9997zm11.4045-6.02l1.9973-3.4592a.416.416 0 00-.1521-.5676.416.416 0 00-.5682.1521l-2.0225 3.503C15.5902 8.2439 13.8533 7.8449 12 7.8449c-1.8533 0-3.5902.399-5.1364 1.1048L4.8411 5.4467a.4161.4161 0 00-.5682-.1521.4157.4157 0 00-.1521.5676l1.9973 3.4592C2.6889 11.1867.3432 14.6589 0 18.761h24c-.3432-4.1021-2.6889-7.5743-6.1185-9.4396z" />
                </svg>
            )
        },
        {
            name: 'iOS',
            icon: (
                <svg className="w-12 h-12" viewBox="0 0 24 24" fill="#000000">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
            )
        },
        {
            name: 'Windows',
            icon: (
                <svg className="w-12 h-12" viewBox="0 0 24 24" fill="#0078D6">
                    <path d="M3 12V6.75l6-1.32v6.48L3 12zm7-6.79l10-2.21v8.75l-10 .15V5.21zm-7 7.79l6 .09v6.81l-6-1.15V13zm7 .1l10 .15V22l-10-1.91V13.1z" />
                </svg>
            )
        },
        {
            name: 'Linux',
            icon: (
                <svg className="w-12 h-12" viewBox="0 0 24 24" fill="#333333">
                    <path d="M12.504 0c-.155 0-.315.008-.48.021-4.226.333-3.105 4.807-3.17 6.298-.076 1.092-.3 1.953-1.05 3.02-.885 1.051-2.127 2.75-2.716 4.521-.278.832-.41 1.684-.287 2.489a.424.424 0 00-.11.135c-.26.268-.45.6-.663.839-.199.199-.485.267-.797.4-.313.136-.658.269-.864.68-.09.189-.136.394-.132.602 0 .199.027.4.055.536.058.399.116.728.04.97-.249.68-.28 1.145-.106 1.484.174.334.535.47.94.601.81.2 1.91.135 2.774.6.926.466 1.866.67 2.616.47.526-.116.97-.464 1.208-.946.587-.003 1.23-.269 2.26-.334.699-.058 1.574.267 2.577.2.025.134.063.198.114.333l.003.003c.391.778 1.113 1.132 1.884 1.071.771-.06 1.592-.536 2.257-1.306.631-.765 1.683-1.084 2.378-1.503.348-.199.629-.469.649-.853.023-.4-.2-.811-.714-1.376v-.097l-.003-.003c-.17-.2-.25-.535-.338-.926-.085-.401-.182-.786-.492-1.046h-.003c-.059-.054-.123-.067-.188-.135a.357.357 0 00-.19-.064c.431-1.278.264-2.55-.173-3.694-.533-1.41-1.465-2.638-2.175-3.483-.796-1.005-1.576-1.957-1.56-3.368.026-2.152.236-6.133-3.544-6.139zm.529 3.405h.013c.213 0 .396.062.584.198.19.135.33.332.438.533.105.259.158.459.166.724 0-.02.006-.04.006-.06v.105a.086.086 0 01-.004-.021l-.004-.024a1.807 1.807 0 01-.15.706.953.953 0 01-.213.335.71.71 0 00-.088-.042c-.104-.045-.198-.064-.284-.133a1.312 1.312 0 00-.22-.066c.05-.06.146-.133.183-.198.053-.128.082-.264.088-.402v-.02a1.21 1.21 0 00-.061-.4c-.045-.134-.101-.2-.183-.333-.084-.066-.167-.132-.267-.132h-.016c-.093 0-.176.03-.262.132a.8.8 0 00-.205.334 1.18 1.18 0 00-.09.4v.019c.002.089.008.179.02.267-.193-.067-.438-.135-.607-.202a1.635 1.635 0 01-.018-.2v-.02a1.772 1.772 0 01.15-.768c.082-.22.232-.406.43-.533a.985.985 0 01.594-.2zm-2.962.059h.036c.142 0 .27.048.399.135.146.129.264.288.344.465.09.199.14.4.153.667v.004c.007.134.006.2-.002.266v.08c-.03.007-.056.018-.083.024-.152.055-.274.135-.393.2.012-.09.013-.18.003-.267v-.015c-.012-.133-.04-.2-.082-.333a.613.613 0 00-.166-.267.248.248 0 00-.183-.064h-.021c-.071.006-.13.04-.186.132a.552.552 0 00-.12.27.944.944 0 00-.023.33v.015c.012.135.037.2.08.334.046.134.098.2.166.268.01.009.02.018.034.024-.07.057-.117.07-.176.136a.304.304 0 01-.131.068 2.62 2.62 0 01-.275-.402 1.772 1.772 0 01-.155-.667 1.759 1.759 0 01.08-.668 1.43 1.43 0 01.283-.535c.128-.133.26-.2.418-.2zm1.37 1.706c.332 0 .733.065 1.216.399.293.2.523.269 1.052.468h.003c.255.136.405.266.478.399v-.131a.571.571 0 01.016.47c-.123.31-.516.643-1.063.842v.002c-.268.135-.501.333-.775.465-.276.135-.588.292-1.012.267a1.139 1.139 0 01-.448-.067 3.566 3.566 0 01-.322-.198c-.195-.135-.363-.332-.612-.465v-.005h-.005c-.4-.246-.616-.512-.686-.71-.07-.268-.005-.47.193-.6.224-.135.38-.271.483-.336.104-.074.143-.102.176-.131h.002v-.003c.169-.202.436-.47.839-.601.139-.036.294-.065.466-.065zm2.8 2.142c.358 1.417 1.196 3.475 1.735 4.473.286.534.855 1.659 1.102 3.024.156-.005.33.018.513.064.646-1.671-.546-3.467-1.089-3.966-.22-.2-.232-.335-.123-.335.59.534 1.365 1.572 1.646 2.757.13.535.16 1.104.021 1.67.067.028.135.06.205.067 1.032.534 1.413.938 1.23 1.537v-.002c-.06-.135-.12-.2-.2-.333-.08-.066-.16-.135-.257-.2h-.005c-.141-.066-.293-.135-.381-.271-.12.135-.241.2-.381.266h-.004c-.12.066-.261.2-.443.2.04.135.06.265.039.4v.002c-.04.135-.1.2-.18.335-.16.269-.4.535-.76.733-.38.199-.79.399-1.22.465-.43.066-.9.066-1.4-.066-.057-.019-.117-.036-.18-.06-.14.358-.381.668-.758.899v.002c.298-.135.582-.335.783-.667.067-.135.102-.2.121-.334v-.003c.02-.135.02-.334-.06-.468-.04-.066-.14-.2-.26-.267-.12-.065-.28-.135-.46-.197-.36-.135-.5-.261-.58-.4-.079-.133-.136-.332-.221-.535-.046-.135-.1-.266-.18-.399-.46-.334-.6-.535-.6-.869 0-.135.02-.27.04-.4a1.5 1.5 0 01.14-.4c-.04-.066-.08-.132-.12-.198-.12-.2-.28-.533-.32-.867-.04-.2-.06-.4-.02-.6.02-.2.08-.4.16-.533.16-.27.36-.469.6-.602.24-.135.48-.2.72-.202.12 0 .24.016.36.05v-.001c.12.033.22.066.32.133.66.269 1.16.875 1.4 1.671.12.466.14 1.002-.08 1.336v.002c-.04.066-.08.135-.14.198l.01-.002c.02.002.04.003.06.008.14.033.3.066.46.135l.04.02c-.08-.4-.2-.867-.36-1.2-.26-.604-.681-1.138-1.14-1.337a3.03 3.03 0 00-.42-.135c-.1-.027-.2-.04-.3-.04-.2-.002-.4.033-.58.135-.18.135-.34.27-.42.468-.08.2-.1.402-.08.601.02.2.08.334.16.534.08.201.22.401.4.533.18.135.4.2.62.268.2.066.4.133.6.265v.002c.2.135.32.334.4.602.06.134.08.268.08.4.06.066.16.135.28.198.12.066.26.066.4.066.12 0 .26 0 .4-.066.12-.065.24-.135.36-.268l-.04.268c0 .133-.04.266-.14.398-.08.135-.26.268-.52.4-.26.135-.54.2-.78.266-.24.066-.46.135-.66.268-.2.135-.36.335-.48.668l.04.066v.002a.77.77 0 00.58.2c.2 0 .38-.066.56-.133.18-.066.34-.2.5-.334.16-.132.3-.331.44-.532.18-.2.22-.468.22-.667 0-.135-.02-.265-.06-.4.5-.2.86-.535 1.06-.802.22-.266.36-.533.44-.733.08-.2.08-.334.04-.401 0-.066-.08-.135-.18-.2-.1-.066-.22-.133-.34-.2-.16-.133-.3-.333-.4-.6a4.33 4.33 0 01-.16-.734c-.06-.333-.1-.667-.14-.999-.04-.334-.14-.602-.24-.867-.04-.135-.1-.268-.18-.4-.08-.134-.18-.268-.3-.401-.24-.27-.52-.469-.84-.535-.32-.067-.64-.067-.96.067-.32.133-.6.332-.82.599-.22.268-.36.601-.44.936-.08.266-.12.6-.1.867.02.2.08.4.16.533l-.04-.001zM7.5 14c.6 0 1.1.4 1.1 1s-.5 1-1.1 1c-.6 0-1.1-.4-1.1-1s.5-1 1.1-1zm9 0c.6 0 1.1.4 1.1 1s-.5 1-1.1 1c-.6 0-1.1-.4-1.1-1s.5-1 1.1-1z" />
                </svg>
            )
        },
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
                                    <div className="w-9 h-9 bg-white rounded-xl flex items-center justify-center flex-shrink-0 shadow-lg shadow-black/5 p-1">
                                        <img src="/src/assets/icon/app_logo.png" alt="Logo" className="w-full h-full object-contain" />
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
                                            <div className={`p-1.5 rounded-lg ${activePreview === 'server' ? 'bg-primary text-white' : 'bg-primary/10 text-primary'}`}>
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
                                                                <div className="w-16 h-14 bg-primary/10 rounded-lg flex items-center justify-center mb-3 group-hover:scale-110 transition-transform duration-300">
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
                                                                            <div className="w-8 h-8 rounded-lg bg-primary/20 flex items-center justify-center">
                                                                                <svg className="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
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
                                                                                <svg className="w-5 h-5 text-primary" fill="currentColor" viewBox="0 0 24 24">
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
                                    ) : activePreview === 'server' ? (
                                        <motion.div
                                            key="server"
                                            initial={{ opacity: 0, scale: 0.95 }}
                                            animate={{ opacity: 1, scale: 1 }}
                                            exit={{ opacity: 0, scale: 0.95 }}
                                            transition={{ duration: 0.4 }}
                                            className="flex-1 flex flex-col p-6 md:p-8 bg-bgWhite overflow-y-auto"
                                        >
                                            <div className="flex items-center justify-between mb-8">
                                                <h2 className="text-xl font-bold text-textBlack">Server Status</h2>
                                            </div>

                                            {/* DISKS Section */}
                                            <div className="mb-8">
                                                <p className="text-xs font-bold text-gray uppercase tracking-wider mb-4">DISKS</p>
                                                <div className="bg-white rounded-2xl p-6 shadow-sm border border-lightGray/60">
                                                    <div className="flex items-center gap-3 mb-4">
                                                        <h3 className="text-lg font-bold text-textBlack">Windows</h3>
                                                        <span className="bg-primary/10 text-primary text-[10px] font-bold px-2 py-0.5 rounded uppercase">SERVER DISK</span>
                                                    </div>
                                                    <p className="text-sm text-gray mb-1">C:</p>
                                                    <div className="flex items-end gap-2 mb-3">
                                                        <span className="text-3xl font-bold text-textBlack">85.3%</span>
                                                        <span className="text-sm text-gray mb-1">used</span>
                                                    </div>

                                                    {/* Progress Bar */}
                                                    <div className="w-full bg-lightGray/50 rounded-full h-3 mb-6 overflow-hidden">
                                                        <motion.div
                                                            initial={{ width: 0 }}
                                                            animate={{ width: '85.3%' }}
                                                            transition={{ duration: 1.5, ease: 'easeOut' }}
                                                            className="h-full bg-primary rounded-full relative"
                                                        >
                                                            <div className="absolute top-0 right-0 bottom-0 w-1 bg-white/20"></div>
                                                        </motion.div>
                                                    </div>

                                                    {/* Stats Grid */}
                                                    <div className="grid grid-cols-3 gap-4">
                                                        <div className="bg-bgWhite rounded-xl p-3 border border-lightGray/40">
                                                            <p className="text-[10px] font-bold text-primary mb-1">Used</p>
                                                            <p className="text-sm font-bold text-textBlack">405.90 GB</p>
                                                        </div>
                                                        <div className="bg-green-50 rounded-xl p-3 border border-green-100">
                                                            <p className="text-[10px] font-bold text-green-600 mb-1">Free</p>
                                                            <p className="text-sm font-bold text-textBlack">69.98 GB</p>
                                                        </div>
                                                        <div className="bg-bgWhite rounded-xl p-3 border border-lightGray/40">
                                                            <p className="text-[10px] font-bold text-gray mb-1">Total</p>
                                                            <p className="text-sm font-bold text-textBlack">475.88 GB</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>

                                            {/* Cloud Quota Section */}
                                            <div>
                                                <p className="text-sm font-bold text-textBlack mb-4">Cloud Quota (Home Screen)</p>
                                                <div className="grid grid-cols-2 gap-4">
                                                    <div className="bg-bgWhite rounded-xl p-4 border border-lightGray/40">
                                                        <p className="text-[10px] font-bold text-gray mb-1">Used / Quota</p>
                                                        <p className="text-sm font-bold text-textBlack">0.0 / 25 GB</p>
                                                    </div>
                                                    <div className="bg-bgWhite rounded-xl p-4 border border-lightGray/40">
                                                        <p className="text-[10px] font-bold text-gray mb-1">Free Quota</p>
                                                        <p className="text-sm font-bold text-textBlack">25 GB</p>
                                                    </div>
                                                </div>
                                            </div>
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
                                                    <div className="w-20 h-20 bg-white rounded-3xl flex items-center justify-center mb-6 shadow-xl shadow-black/5 p-3">
                                                        <img src="/src/assets/icon/app_logo.png" alt="HomeCloud Logo" className="w-full h-full object-contain" />
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
                                    className="mb-3 block"
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
