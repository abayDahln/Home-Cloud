import { useLanguage } from '../context/LanguageContext'
import { Timeline } from '../components/ui/Timeline'
import React from 'react'

const HowToUse = () => {
    const { t } = useLanguage()

    const timelineData = React.useMemo(() => [
        {
            title: t.howToUse.step1,
            content: (
                <div>
                    <h4 className="text-xl md:text-2xl font-bold text-textBlack mb-2">
                        {t.howToUse.serverSetup}
                    </h4>
                    <p className="text-gray mb-6">
                        {t.howToUse.serverSetupDesc}
                    </p>
                    <div className="grid gap-4">
                        {t.howToUse.serverSteps.map((step, index) => (
                            <div key={index} className="flex gap-4 p-4 rounded-2xl bg-white border border-lightGray/50 shadow-sm hover:shadow-lg hover:border-primary/20 hover:-translate-y-1 transition-all duration-300 group/step">
                                <div className="flex-shrink-0 w-10 h-10 bg-primary/5 text-primary rounded-xl flex items-center justify-center font-bold text-sm group-hover/step:bg-primary group-hover/step:text-white transition-colors duration-300">
                                    {index + 1}
                                </div>
                                <div>
                                    <h5 className="font-bold text-textBlack mb-1">{step.title}</h5>
                                    <p className="text-sm text-gray">{step.description}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                    {/* Requirements Box */}
                    <div className="mt-6 bg-gradient-to-r from-primary/5 to-primary-light3/10 rounded-2xl p-5 border border-primary/10">
                        <h4 className="font-bold text-textBlack mb-3 flex items-center gap-2">
                            {t.howToUse.serverRequirements}
                        </h4>
                        <ul className="grid md:grid-cols-2 gap-2 text-gray text-sm">
                            {t.download.reqServer.map((req, i) => (
                                <li key={i} className="flex items-center gap-2">
                                    <span className="w-2 h-2 bg-primary rounded-full"></span>
                                    {req.replace('• ', '')}
                                </li>
                            ))}
                        </ul>
                    </div>
                </div>
            ),
        },
        {
            title: t.howToUse.step2,
            content: (
                <div>
                    <h4 className="text-xl md:text-2xl font-bold text-textBlack mb-2">
                        {t.howToUse.clientSetup}
                    </h4>
                    <p className="text-gray mb-6">
                        {t.howToUse.clientSetupDesc}
                    </p>
                    <div className="grid gap-4">
                        {t.howToUse.appSteps.map((step, index) => (
                            <div key={index} className="flex gap-4 p-4 rounded-2xl bg-white border border-lightGray/50 shadow-sm hover:shadow-lg hover:border-primary/20 hover:-translate-y-1 transition-all duration-300 group/step">
                                <div className="flex-shrink-0 w-10 h-10 bg-primary/5 text-primary rounded-xl flex items-center justify-center font-bold text-sm group-hover/step:bg-primary group-hover/step:text-white transition-colors duration-300">
                                    {index + 1}
                                </div>
                                <div>
                                    <h5 className="font-bold text-textBlack mb-1">{step.title}</h5>
                                    <p className="text-sm text-gray">{step.description}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            ),
        },
        {
            title: t.howToUse.step3,
            content: (
                <div>
                    <h4 className="text-xl md:text-2xl font-bold text-textBlack mb-2">
                        {t.howToUse.connectionGuide}
                    </h4>
                    <p className="text-gray mb-6">
                        {t.howToUse.ensureServerOnDesc}
                    </p>
                    <div className="space-y-4">
                        <div className="flex items-start gap-4 p-4 rounded-2xl bg-white border border-lightGray/50 shadow-sm hover:shadow-lg hover:border-primary/20 hover:-translate-y-1 transition-all duration-300 group/step">
                            <div className="flex-shrink-0 w-10 h-10 bg-primary/10 text-primary rounded-full flex items-center justify-center font-bold text-sm group-hover/step:bg-primary group-hover/step:text-white transition-colors duration-300">1</div>
                            <div>
                                <h4 className="font-bold text-textBlack mb-1">{t.howToUse.ensureServerOn}</h4>
                                <p className="text-gray text-sm">{t.howToUse.ensureServerOnDesc}</p>
                            </div>
                        </div>
                        <div className="flex items-start gap-4 p-4 rounded-2xl bg-white border border-lightGray/50 shadow-sm hover:shadow-lg hover:border-primary/20 hover:-translate-y-1 transition-all duration-300 group/step">
                            <div className="flex-shrink-0 w-10 h-10 bg-primary/10 text-primary rounded-full flex items-center justify-center font-bold text-sm group-hover/step:bg-primary group-hover/step:text-white transition-colors duration-300">2</div>
                            <div>
                                <h4 className="font-bold text-textBlack mb-1">{t.howToUse.findIp}</h4>
                                <p className="text-gray text-sm">{t.howToUse.findIpDesc}</p>
                            </div>
                        </div>
                        <div className="flex items-start gap-4 p-4 rounded-2xl bg-white border border-lightGray/50 shadow-sm hover:shadow-lg hover:border-primary/20 hover:-translate-y-1 transition-all duration-300 group/step">
                            <div className="flex-shrink-0 w-10 h-10 bg-primary/10 text-primary rounded-full flex items-center justify-center font-bold text-sm group-hover/step:bg-primary group-hover/step:text-white transition-colors duration-300">3</div>
                            <div>
                                <h4 className="font-bold text-textBlack mb-1">{t.howToUse.enterAddress}</h4>
                                <p className="text-gray text-sm">
                                    {t.howToUse.enterAddressDesc} <br />
                                    {t.howToUse.enterAddressExample}
                                </p>
                            </div>
                        </div>
                        <div className="flex items-start gap-4 p-5 bg-green-50/50 border border-green-200/60 rounded-2xl shadow-sm hover:shadow-lg hover:-translate-y-1 transition-all duration-300 group/step">
                            <div className="flex-shrink-0 w-10 h-10 bg-green-100 text-green-600 rounded-full flex items-center justify-center font-bold shadow-sm group-hover/step:bg-green-500 group-hover/step:text-white transition-colors duration-300">✓</div>
                            <div>
                                <h4 className="font-bold text-textBlack mb-1">{t.howToUse.done}</h4>
                                <p className="text-gray text-sm">{t.howToUse.doneDesc}</p>
                            </div>
                        </div>

                        {/* Optional Configuration */}
                        <div className="mt-4 pt-4 border-t border-dashed border-lightGray">
                            <div className="flex items-start gap-4 p-4 rounded-2xl bg-gray-50 border border-gray-100 shadow-sm group/step">
                                <div className="flex-shrink-0 w-10 h-10 bg-gray-200 text-gray-600 rounded-full flex items-center justify-center font-bold text-sm">opt</div>
                                <div>
                                    <h4 className="font-bold text-textBlack mb-1">{t.howToUse.optionalConfig}</h4>
                                    <p className="text-gray text-sm">{t.howToUse.optionalConfigDesc}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            ),
        },
    ], [t]);

    const featureList = [
        {
            icon: (
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                </svg>
            ),
            title: t.howToUse.uploadDownload,
            description: t.howToUse.uploadDownloadDesc,
        },
        {
            icon: (
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
            ),
            title: t.howToUse.autoBackup,
            description: t.howToUse.autoBackupDesc,
        },
        {
            icon: (
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2" />
                </svg>
            ),
            title: t.howToUse.fileManager,
            description: t.howToUse.fileManagerDesc,
        },
        {
            icon: (
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
            ),
            title: t.howToUse.mediaPlayer,
            description: t.howToUse.mediaPlayerDesc,
        },
        {
            icon: (
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
            ),
            title: t.features.serverMonitoring,
            description: t.howToUse.serverMonitoringDesc || t.features.serverMonitoringDesc,
        },
        {
            icon: (
                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
            ),
            title: t.howToUse.secureAccess,
            description: t.howToUse.secureAccessDesc,
        },
    ]

    return (
        <div className="w-full bg-white font-sans">
            {/* Hero */}
            <section className="pt-32 pb-10 px-6 lg:px-8 text-center bg-bgWhite">
                <div className="max-w-screen-2xl mx-auto">
                    <h1 className="text-4xl md:text-5xl font-bold text-textBlack mb-6">
                        {t.howToUse.title} <span className="gradient-text">HomeCloud</span>
                    </h1>
                    <p className="text-lg text-gray max-w-2xl mx-auto">
                        {t.howToUse.subtitle}
                    </p>
                </div>
            </section>

            {/* Timeline Section */}
            <Timeline data={timelineData} />

            {/* Features Overview */}
            <section className="py-20 px-6 lg:px-8 bg-bgWhite">
                <div className="max-w-screen-2xl mx-auto">
                    <div className="text-center mb-16">
                        <h2 className="text-3xl font-bold text-textBlack mb-4">
                            {t.howToUse.featuresTitle}
                        </h2>
                        <p className="text-gray max-w-2xl mx-auto">
                            {t.howToUse.featuresDesc}
                        </p>
                    </div>
                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
                        {featureList.map((feature, index) => (
                            <div key={index} className="card group">
                                <div className="w-14 h-14 bg-primary/10 text-primary rounded-xl flex items-center justify-center mb-4 group-hover:bg-primary group-hover:text-white transition-all duration-300">
                                    {feature.icon}
                                </div>
                                <h3 className="text-xl font-bold text-textBlack mb-2">{feature.title}</h3>
                                <p className="text-gray">{feature.description}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Tips Section */}
            <section className="py-20 px-6 lg:px-8 bg-white">
                <div className="max-w-6xl mx-auto">
                    <h2 className="text-3xl font-bold text-textBlack mb-12 text-center">{t.howToUse.tips}</h2>
                    <div className="grid md:grid-cols-2 gap-8">
                        <div className="card border-l-4 border-l-primary">
                            <h4 className="font-bold text-textBlack mb-2">{t.howToUse.tipRemote}</h4>
                            <p className="text-gray text-sm">{t.howToUse.tipRemoteDesc}</p>
                        </div>
                        <div className="card border-l-4 border-l-primary">
                            <h4 className="font-bold text-textBlack mb-2">{t.howToUse.tipSecurity}</h4>
                            <p className="text-gray text-sm">{t.howToUse.tipSecurityDesc}</p>
                        </div>
                        <div className="card border-l-4 border-l-primary">
                            <h4 className="font-bold text-textBlack mb-2">{t.howToUse.tipBackup}</h4>
                            <p className="text-gray text-sm">{t.howToUse.tipBackupDesc}</p>
                        </div>
                        <div className="card border-l-4 border-l-primary">
                            <h4 className="font-bold text-textBlack mb-2">{t.howToUse.tipAlwaysOn}</h4>
                            <p className="text-gray text-sm">{t.howToUse.tipAlwaysOnDesc}</p>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    )
}

export default HowToUse

