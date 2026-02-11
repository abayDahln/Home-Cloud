import { useLanguage } from '../context/LanguageContext'
import { motion } from 'framer-motion'

const About = () => {
    const { t } = useLanguage()

    const howItWorks = [
        {
            step: '01',
            title: t.about.step1Title,
            description: t.about.step1Desc,
            color: 'from-primary to-primary-dark1',
        },
        {
            step: '02',
            title: t.about.step2Title,
            description: t.about.step2Desc,
            color: 'from-purple-500 to-pink-600',
        },
        {
            step: '03',
            title: t.about.step3Title,
            description: t.about.step3Desc,
            color: 'from-emerald-500 to-teal-600',
        },
    ]

    const techStack = [
        { name: 'Flutter', description: 'Cross-platform mobile & desktop framework', icon: '📱', color: 'bg-blue-50 text-blue-500' },
        { name: 'Go', description: 'High-performance backend server', icon: '🚀', color: 'bg-cyan-50 text-cyan-500' },
    ]

    const stats = [
        { label: t.about.statsPrivate, value: '100%', sub: 'Secure' },
        { label: t.about.statsFee, value: '$0', sub: 'Lifetime' },
        { label: t.about.statsPlatforms, value: '5+', sub: 'Clients' },
        { label: t.about.statsStorage, value: '∞', sub: 'Unlimited' },
    ]

    // Animation Variants
    const containerV = { hidden: {}, visible: { transition: { staggerChildren: 0.1 } } }
    const fadeUp = { hidden: { opacity: 0, y: 30 }, visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: 'easeOut' } } }
    const scaleUp = { hidden: { opacity: 0, scale: 0.8 }, visible: { opacity: 1, scale: 1, transition: { duration: 0.5, ease: 'easeOut' } } }

    return (
        <div className="pt-24 min-h-screen overflow-hidden">
            {/* Background Atmosphere */}
            <div className="fixed inset-0 pointer-events-none -z-10 bg-bgWhite">
                <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-primary/5 rounded-full blur-[100px] -translate-y-1/2 translate-x-1/2" />
                <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-primary-light2/5 rounded-full blur-[100px] translate-y-1/2 -translate-x-1/2" />
            </div>

            {/* Hero */}
            <section className="py-20 px-6 lg:px-8 relative">
                <motion.div
                    initial="hidden"
                    animate="visible"
                    variants={containerV}
                    className="max-w-4xl mx-auto text-center"
                >
                    <motion.div variants={fadeUp} className="inline-block mb-4 px-4 py-1.5 rounded-full bg-primary/10 text-primary font-bold text-sm">
                        Our Story
                    </motion.div>
                    <motion.h1 variants={fadeUp} className="text-4xl md:text-6xl font-extrabold text-textBlack mb-6 tracking-tight">
                        {t.about.title} <span className="gradient-text">Home Cloud</span>
                    </motion.h1>
                    <motion.p variants={fadeUp} className="text-xl text-gray font-light max-w-2xl mx-auto leading-relaxed">
                        {t.about.subtitle}
                    </motion.p>
                </motion.div>
            </section>

            {/* What is HomeCloud + Stats */}
            <section className="py-20 px-6 lg:px-8">
                <div className="max-w-screen-2xl mx-auto">
                    <div className="grid lg:grid-cols-2 gap-16 items-center">
                        <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={containerV}>
                            <motion.h2 variants={fadeUp} className="text-3xl md:text-4xl font-bold text-textBlack mb-6">
                                {t.about.whatIsTitle}
                            </motion.h2>
                            <motion.div variants={fadeUp} className="space-y-6 text-gray text-lg leading-relaxed">
                                <p>{t.about.whatIsDesc1}</p>
                                <p className="border-l-4 border-primary pl-4 italic text-textBlack/80">
                                    "{t.about.whatIsDesc2}"
                                </p>
                                <p>{t.about.whatIsDesc3}</p>
                            </motion.div>
                        </motion.div>

                        <motion.div
                            initial="hidden"
                            whileInView="visible"
                            viewport={{ once: true }}
                            variants={containerV}
                            className="relative"
                        >
                            {/* Decorative background for grid */}
                            <div className="absolute inset-0 bg-gradient-to-br from-primary/5 to-primary-light3/10 rounded-3xl -rotate-2 scale-105 blur-xl" />

                            <div className="relative grid grid-cols-2 gap-4">
                                {stats.map((stat, i) => (
                                    <motion.div
                                        key={i}
                                        variants={scaleUp}
                                        whileHover={{ y: -5, boxShadow: "0 10px 30px -10px rgba(0,0,0,0.1)" }}
                                        className="bg-white rounded-2xl p-8 text-center shadow-lg border border-lightGray/50 transition-all duration-300"
                                    >
                                        <div className="text-4xl md:text-5xl font-extrabold gradient-text mb-2">
                                            {stat.value}
                                        </div>
                                        <div className="text-textBlack font-bold mb-1">{stat.label}</div>
                                        <div className="text-xs text-gray uppercase tracking-wider">{stat.sub}</div>
                                    </motion.div>
                                ))}
                            </div>
                        </motion.div>
                    </div>
                </div>
            </section>

            {/* How it Works */}
            <section className="py-24 px-6 lg:px-8 bg-white relative overflow-hidden">
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full h-px bg-gradient-to-r from-transparent via-lightGray to-transparent" />

                <div className="max-w-screen-2xl mx-auto">
                    <motion.div
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        variants={containerV}
                        className="text-center mb-20"
                    >
                        <motion.h2 variants={fadeUp} className="text-3xl md:text-4xl font-bold text-textBlack mb-4">
                            {t.about.howItWorksTitle}
                        </motion.h2>
                        <motion.p variants={fadeUp} className="text-gray text-lg max-w-2xl mx-auto">
                            {t.about.howItWorksDesc}
                        </motion.p>
                    </motion.div>

                    <div className="relative grid md:grid-cols-3 gap-12">
                        {/* Connecting Line (Desktop) */}
                        <div className="hidden md:block absolute top-12 left-[16%] right-[16%] h-0.5 bg-gradient-to-r from-lightGray via-primary/30 to-lightGray border-t border-dashed border-gray/30 z-0" />

                        {howItWorks.map((item, index) => (
                            <motion.div
                                key={index}
                                initial={{ opacity: 0, y: 30 }}
                                whileInView={{ opacity: 1, y: 0 }}
                                viewport={{ once: true }}
                                transition={{ delay: index * 0.2, duration: 0.6 }}
                                className="relative z-10 text-center group"
                            >
                                <div className={`w-24 h-24 mx-auto bg-gradient-to-br ${item.color} rounded-full flex items-center justify-center text-white text-3xl font-bold mb-8 shadow-xl shadow-primary/10 group-hover:scale-110 transition-transform duration-500`}>
                                    {item.step}
                                </div>
                                <h3 className="text-xl font-bold text-textBlack mb-3">{item.title}</h3>
                                <p className="text-gray leading-relaxed px-4">{item.description}</p>
                            </motion.div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Tech Stack */}
            <section className="py-24 px-6 lg:px-8">
                <div className="max-w-screen-2xl mx-auto">
                    <motion.div
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        variants={containerV}
                        className="text-center mb-16"
                    >
                        <motion.h2 variants={fadeUp} className="text-3xl font-bold text-textBlack mb-4">Built With Modern Technology</motion.h2>
                        <motion.p variants={fadeUp} className="text-gray max-w-2xl mx-auto">
                            Home Cloud is built using the latest technologies for optimal performance, security, and reliability.
                        </motion.p>
                    </motion.div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-3xl mx-auto">
                        {techStack.map((tech, index) => (
                            <motion.div
                                key={index}
                                initial="hidden"
                                whileInView="visible"
                                viewport={{ once: true }}
                                variants={scaleUp}
                                whileHover={{ y: -8 }}
                                className="bg-white rounded-2xl p-8 text-center shadow-lg hover:shadow-xl border border-lightGray/50 transition-all duration-300 group"
                            >
                                <div className={`w-16 h-16 mx-auto ${tech.color} rounded-2xl flex items-center justify-center text-3xl mb-6 group-hover:scale-110 transition-transform duration-300`}>
                                    {tech.icon}
                                </div>
                                <h3 className="text-xl font-bold text-textBlack mb-2">{tech.name}</h3>
                                <p className="text-gray text-sm">{tech.description}</p>
                            </motion.div>
                        ))}
                    </div>
                </div>
            </section>
        </div>
    )
}

export default About
