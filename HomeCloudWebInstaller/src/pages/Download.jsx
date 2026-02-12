import { useLanguage } from '../context/LanguageContext'
import { motion, AnimatePresence } from 'framer-motion'
import { useState, useRef } from 'react'

// Depth Tilt Card — tilts toward cursor, springs back on leave
const TiltCard = ({ children, className, style, onMouseEnter: externalEnter, onMouseLeave: externalLeave, ...props }) => {
    const ref = useRef(null)
    const [tilt, setTilt] = useState({ rotateX: 0, rotateY: 0 })
    const [isHovered, setIsHovered] = useState(false)

    const handleMouse = (e) => {
        if (!ref.current) return
        const rect = ref.current.getBoundingClientRect()
        const centerX = rect.left + rect.width / 2
        const centerY = rect.top + rect.height / 2
        const rotateY = ((e.clientX - centerX) / (rect.width / 2)) * 10
        const rotateX = ((centerY - e.clientY) / (rect.height / 2)) * 10
        setTilt({ rotateX, rotateY })
    }

    const handleEnter = (e) => {
        setIsHovered(true)
        externalEnter?.(e)
    }
    const handleLeave = (e) => {
        setIsHovered(false)
        setTilt({ rotateX: 0, rotateY: 0 })
        externalLeave?.(e)
    }

    return (
        <motion.div
            ref={ref}
            onMouseMove={handleMouse}
            onMouseEnter={handleEnter}
            onMouseLeave={handleLeave}
            animate={{
                rotateX: tilt.rotateX,
                rotateY: tilt.rotateY,
                scale: isHovered ? 1.03 : 1,
            }}
            transition={
                isHovered
                    ? { type: 'tween', duration: 0.1, ease: 'linear' }
                    : { type: 'spring', stiffness: 200, damping: 10, mass: 0.8 }
            }
            style={{ transformPerspective: 800, transformStyle: 'preserve-3d', ...style }}
            className={className}
            {...props}
        >
            {children}
        </motion.div>
    )
}

const Download = () => {
    const { t } = useLanguage()
    const [hoveredCard, setHoveredCard] = useState(null)
    const [downloadingStates, setDownloadingStates] = useState({})
    const [completedDownloads, setCompletedDownloads] = useState({})
    const [serverDownloading, setServerDownloading] = useState({})
    const [serverCompleted, setServerCompleted] = useState({})
    const [serverHovered, setServerHovered] = useState(null)

    const platforms = [
        {
            name: 'Android', category: 'MOBILE APP',
            iconColor: 'text-[#3DDC84]', // Android green
            icon: (
                <svg className="w-14 h-14" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.523 15.34c-.5 0-.909-.407-.909-.91s.408-.91.91-.91.909.408.909.91-.409.91-.91.91m-11.046 0c-.5 0-.909-.407-.909-.91s.408-.91.91-.91.909.408.909.91-.409.91-.91.91M17.8 8.29l1.877-3.25c.104-.18.044-.41-.136-.514-.18-.104-.408-.044-.512.136l-1.9 3.29c-1.3-.598-2.774-.93-4.128-.93-1.355 0-2.83.332-4.129.93l-1.9-3.29c-.104-.18-.332-.24-.512-.136-.18.104-.24.334-.136.514L8.2 8.29C4.82 10.05 2.5 13.48 2.5 17.393h19c0-3.914-2.32-7.342-5.7-9.103" />
                </svg>
            ),
            version: 'v1.0.0', size: '~25 MB', fileName: 'HomeCloud-Android.apk',
            downloadUrl: 'https://github.com/abayDahln/Home-Cloud/releases/download/v1.0a/HomeCloudApp-Android.apk', available: true, popular: true,
            features: ['Android 7.0+', 'Auto Photo Backup', 'Background Sync', 'Offline Access']
        },
        {
            name: 'iOS', category: 'MOBILE APP',
            iconColor: 'text-[#A2AAAD]', // Apple gray
            label: t.download.experimental,
            labelColor: 'bg-orange-500',
            icon: (
                <svg className="w-14 h-14" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
            ),
            version: 'v1.0.0', size: '~30 MB', fileName: 'HomeCloud-iOS.ipa',
            downloadUrl: 'https://github.com/abayDahln/Home-Cloud/releases/download/v1.0a/HomeCloudApp-iOS.ipa', available: true, popular: false,
            features: ['iOS 12.0+', 'Secure Enclave', 'FaceID Support', 'iCloud Sync']
        },
        {
            name: 'Windows', category: 'DESKTOP APP',
            iconColor: 'text-[#0078D4]', // Windows blue
            icon: (
                <svg className="w-14 h-14" viewBox="0 0 24 24">
                    <path d="M3 12V6.75l6-1.32v6.48L3 12" fill="#F25022" />
                    <path d="M10 5.21l10-2.21v8.75l-10 .15V5.21" fill="#7FBA00" />
                    <path d="M3 13l6 .09v6.81l-6-1.15V13" fill="#00A4EF" />
                    <path d="M10 13.1l10 .15V22l-10-1.91V13.1" fill="#FFB900" />
                </svg>
            ),
            version: 'v1.0.0', size: '~45 MB', fileName: 'HomeCloudAppSetup.exe',
            downloadUrl: 'https://github.com/abayDahln/Home-Cloud/releases/download/v1.0a/HomeCloudAppSetup.exe', available: true, popular: false,
            features: ['Windows 10/11 (64-bit)', 'Native Performance', 'Auto Updates', 'System Tray Integration']
        },
        {
            name: 'Linux', category: 'DESKTOP APP',
            iconColor: 'text-[#333333]', // Linux dark
            label: t.download.beta,
            labelColor: 'bg-yellow-500',
            icon: (
                <svg className="w-14 h-14" viewBox="0 0 24 24" fill="#333333">
                    <path d="M12.504 0c-.155 0-.315.008-.48.021-4.226.333-3.105 4.807-3.17 6.298-.076 1.092-.3 1.953-1.05 3.02-.885 1.051-2.127 2.75-2.716 4.521-.278.832-.41 1.684-.287 2.489a.424.424 0 00-.11.135c-.26.268-.45.6-.663.839-.199.199-.485.267-.797.4-.313.136-.658.269-.864.68-.09.189-.136.394-.132.602 0 .199.027.4.055.536.058.399.116.728.04.97-.249.68-.28 1.145-.106 1.484.174.334.535.47.94.601.81.2 1.91.135 2.774.6.926.466 1.866.67 2.616.47.526-.116.97-.464 1.208-.946.587-.003 1.23-.269 2.26-.334.699-.058 1.574.267 2.577.2.025.134.063.198.114.333l.003.003c.391.778 1.113 1.132 1.884 1.071.771-.06 1.592-.536 2.257-1.306.631-.765 1.683-1.084 2.378-1.503.348-.199.629-.469.649-.853.023-.4-.2-.811-.714-1.376v-.097l-.003-.003c-.17-.2-.25-.535-.338-.926-.085-.401-.182-.786-.492-1.046h-.003c-.059-.054-.123-.067-.188-.135a.357.357 0 00-.19-.064c.431-1.278.264-2.55-.173-3.694-.533-1.41-1.465-2.638-2.175-3.483-.796-1.005-1.576-1.957-1.56-3.368.026-2.152.236-6.133-3.544-6.139zm.529 3.405h.013c.213 0 .396.062.584.198.19.135.33.332.438.533.105.259.158.459.166.724 0-.02.006-.04.006-.06v.105a.086.086 0 01-.004-.021l-.004-.024a1.807 1.807 0 01-.15.706.953.953 0 01-.213.335.71.71 0 00-.088-.042c-.104-.045-.198-.064-.284-.133a1.312 1.312 0 00-.22-.066c.05-.06.146-.133.183-.198.053-.128.082-.264.088-.402v-.02a1.21 1.21 0 00-.061-.4c-.045-.134-.101-.2-.183-.333-.084-.066-.167-.132-.267-.132h-.016c-.093 0-.176.03-.262.132a.8.8 0 00-.205.334 1.18 1.18 0 00-.09.4v.019c.002.089.008.179.02.267-.193-.067-.438-.135-.607-.202a1.635 1.635 0 01-.018-.2v-.02a1.772 1.772 0 01.15-.768c.082-.22.232-.406.43-.533a.985.985 0 01.594-.2zm-2.962.059h.036c.142 0 .27.048.399.135.146.129.264.288.344.465.09.199.14.4.153.667v.004c.007.134.006.2-.002.266v.08c-.03.007-.056.018-.083.024-.152.055-.274.135-.393.2.012-.09.013-.18.003-.267v-.015c-.012-.133-.04-.2-.082-.333a.613.613 0 00-.166-.267.248.248 0 00-.183-.064h-.021c-.071.006-.13.04-.186.132a.552.552 0 00-.12.27.944.944 0 00-.023.33v.015c.012.135.037.2.08.334.046.134.098.2.166.268.01.009.02.018.034.024-.07.057-.117.07-.176.136a.304.304 0 01-.131.068 2.62 2.62 0 01-.275-.402 1.772 1.772 0 01-.155-.667 1.759 1.759 0 01.08-.668 1.43 1.43 0 01.283-.535c.128-.133.26-.2.418-.2zm1.37 1.706c.332 0 .733.065 1.216.399.293.2.523.269 1.052.468h.003c.255.136.405.266.478.399v-.131a.571.571 0 01.016.47c-.123.31-.516.643-1.063.842v.002c-.268.135-.501.333-.775.465-.276.135-.588.292-1.012.267a1.139 1.139 0 01-.448-.067 3.566 3.566 0 01-.322-.198c-.195-.135-.363-.332-.612-.465v-.005h-.005c-.4-.246-.616-.512-.686-.71-.07-.268-.005-.47.193-.6.224-.135.38-.271.483-.336.104-.074.143-.102.176-.131h.002v-.003c.169-.202.436-.47.839-.601.139-.036.294-.065.466-.065zm2.8 2.142c.358 1.417 1.196 3.475 1.735 4.473.286.534.855 1.659 1.102 3.024.156-.005.33.018.513.064.646-1.671-.546-3.467-1.089-3.966-.22-.2-.232-.335-.123-.335.59.534 1.365 1.572 1.646 2.757.13.535.16 1.104.021 1.67.067.028.135.06.205.067 1.032.534 1.413.938 1.23 1.537v-.002c-.06-.135-.12-.2-.333-.08-.066-.16-.135-.257-.2h-.005c-.141-.066-.293-.135-.381-.271-.12.135-.241.2-.381.266h-.004c-.12.066-.261.2-.443.2.04.135.06.265.039.4v.002c-.04.135-.1.2-.18.335-.16.269-.4.535-.76.733-.38.199-.79.399-1.22.465-.43.066-.9.066-1.4-.066-.057-.019-.117-.036-.18-.06-.14.358-.381.668-.758.899v.002c.298-.135.582-.335.783-.667.067-.135.102-.2.121-.334v-.003c.02-.135.02-.334-.06-.468-.04-.066-.14-.2-.26-.267-.12-.065-.28-.135-.46-.197-.36-.135-.5-.261-.58-.4-.079-.133-.136-.332-.221-.535-.046-.135-.1-.266-.18-.399-.46-.334-.6-.535-.6-.869 0-.135.02-.27.04-.4a1.5 1.5 0 01.14-.4c-.04-.066-.08-.132-.12-.198-.12-.2-.28-.533-.32-.867-.04-.2-.06-.4-.02-.6.02-.2.08-.4.16-.533.16-.27.36-.469.6-.602.24-.135.48-.2.72-.202.12 0 .24.016.36.05v-.001c.12.033.22.066.32.133.66.269 1.16.875 1.4 1.671.12.466.14 1.002-.08 1.336v.002c-.04.066-.08.135-.14.198l.01-.002c.02.002.04.003.06.008.14.033.3.066.46.135l.04.02c-.08-.4-.2-.867-.36-1.2-.26-.604-.681-1.138-1.14-1.337a3.03 3.03 0 00-.42-.135c-.1-.027-.2-.04-.3-.04-.2-.002-.4.033-.58.135-.18.135-.34.27-.42.468-.08.2-.1.402-.08.601.02.2.08.334.16.534.08.201.22.401.4.533.18.135.4.2.62.268.2.066.4.133.6.265v.002c.2.135.32.334.4.602.06.134.08.268.08.4.06.066.16.135.28.198.12.066.26.066.4.066.12 0 .26 0 .4-.066.12-.065.24-.135.36-.268l-.04.268c0 .133-.04.266-.14.398-.08.135-.26.268-.52.4-.26.135-.54.2-.78.266-.24.066-.46.135-.66.268-.2.135-.36.335-.48.668l.04.066v.002a.77.77 0 00.58.2c.2 0 .38-.066.56-.133.18-.066.34-.2.5-.334.16-.132.3-.331.44-.532.18-.2.22-.468.22-.667 0-.135-.02-.265-.06-.4.5-.2.86-.535 1.06-.802.22-.266.36-.533.44-.733.08-.2.08-.334.04-.401 0-.066-.08-.135-.18-.2-.1-.066-.22-.133-.34-.2-.16-.133-.3-.333-.4-.6a4.33 4.33 0 01-.16-.734c-.06-.333-.1-.667-.14-.999-.04-.334-.14-.602-.24-.867-.04-.135-.1-.268-.18-.4-.08-.134-.18-.268-.3-.401-.24-.27-.52-.469-.84-.535-.32-.067-.64-.067-.96.067-.32.133-.6.332-.82.599-.22.268-.36.601-.44.936-.08.266-.12.6-.1.867.02.2.08.4.16.533l-.04-.001zM7.5 14c.6 0 1.1.4 1.1 1s-.5 1-1.1 1c-.6 0-1.1-.4-1.1-1s.5-1 1.1-1zm9 0c.6 0 1.1.4 1.1 1s-.5 1-1.1 1c-.6 0-1.1-.4-1.1-1s.5-1 1.1-1z" />
                </svg>
            ),
            version: 'v1.0.0', size: '~40 MB', fileName: 'HomeCloudApp-Linux.zip',
            downloadUrl: 'https://github.com/abayDahln/Home-Cloud/releases/download/v1.0a/HomeCloudApp-Linux.zip', available: true, popular: false,
            features: ['AppImage / Deb', 'Debian/Ubuntu/Arch', 'CLI Support', 'Lightweight']
        },
    ]

    const serverDownloads = [
        {
            name: 'Windows Manager',
            icon: (
                <svg className="w-14 h-14" viewBox="0 0 24 24">
                    <path d="M3 12V6.75l6-1.32v6.48L3 12" fill="#F25022" />
                    <path d="M10 5.21l10-2.21v8.75l-10 .15V5.21" fill="#7FBA00" />
                    <path d="M3 13l6 .09v6.81l-6-1.15V13" fill="#00A4EF" />
                    <path d="M10 13.1l10 .15V22l-10-1.91V13.1" fill="#FFB900" />
                </svg>
            ),
            fileName: 'HomeCloudServerInstaller.exe',
            downloadUrl: 'https://github.com/abayDahln/Home-Cloud/releases/download/v1.0s/HomeCloudServerInstaller.exe',
            description: 'GUI Manager for Windows 10/11. Includes Go Backend.'
        },
        {
            name: 'macOS Manager',
            icon: (
                <svg className="w-14 h-14" viewBox="0 0 24 24" fill="#A2AAAD">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                </svg>
            ),
            label: t.download.experimental,
            labelColor: 'bg-orange-500',
            fileName: 'HomeCloudServer-macOS.dmg',
            downloadUrl: 'https://github.com/abayDahln/Home-Cloud/releases/download/v1.0s/HomeCloudServer-macOS.dmg',
            description: 'Native app for macOS (Intel/Silicon).'
        },
        {
            name: 'Linux Manager',
            icon: (
                <svg className="w-14 h-14" viewBox="0 0 24 24" fill="#333333">
                    <path d="M12.504 0c-.155 0-.315.008-.48.021-4.226.333-3.105 4.807-3.17 6.298-.076 1.092-.3 1.953-1.05 3.02-.885 1.051-2.127 2.75-2.716 4.521-.278.832-.41 1.684-.287 2.489a.424.424 0 00-.11.135c-.26.268-.45.6-.663.839-.199.199-.485.267-.797.4-.313.136-.658.269-.864.68-.09.189-.136.394-.132.602 0 .199.027.4.055.536.058.399.116.728.04.97-.249.68-.28 1.145-.106 1.484.174.334.535.47.94.601.81.2 1.91.135 2.774.6.926.466 1.866.67 2.616.47.526-.116.97-.464 1.208-.946.587-.003 1.23-.269 2.26-.334.699-.058 1.574.267 2.577.2.025.134.063.198.114.333l.003.003c.391.778 1.113 1.132 1.884 1.071.771-.06 1.592-.536 2.257-1.306.631-.765 1.683-1.084 2.378-1.503.348-.199.629-.469.649-.853.023-.4-.2-.811-.714-1.376v-.097l-.003-.003c-.17-.2-.25-.535-.338-.926-.085-.401-.182-.786-.492-1.046h-.003c-.059-.054-.123-.067-.188-.135a.357.357 0 00-.19-.064c.431-1.278.264-2.55-.173-3.694-.533-1.41-1.465-2.638-2.175-3.483-.796-1.005-1.576-1.957-1.56-3.368.026-2.152.236-6.133-3.544-6.139zm.529 3.405h.013c.213 0 .396.062.584.198.19.135.33.332.438.533.105.259.158.459.166.724 0-.02.006-.04.006-.06v.105a.086.086 0 01-.004-.021l-.004-.024a1.807 1.807 0 01-.15.706.953.953 0 01-.213.335.71.71 0 00-.088-.042c-.104-.045-.198-.064-.284-.133a1.312 1.312 0 00-.22-.066c.05-.06.146-.133.183-.198.053-.128.082-.264.088-.402v-.02a1.21 1.21 0 00-.061-.4c-.045-.134-.101-.2-.183-.333-.084-.066-.167-.132-.267-.132h-.016c-.093 0-.176.03-.262.132a.8.8 0 00-.205.334 1.18 1.18 0 00-.09.4v.019c.002.089.008.179.02.267-.193-.067-.438-.135-.607-.202a1.635 1.635 0 01-.018-.2v-.02a1.772 1.772 0 01.15-.768c.082-.22.232-.406.43-.533a.985.985 0 01.594-.2zm-2.962.059h.036c.142 0 .27.048.399.135.146.129.264.288.344.465.09.199.14.4.153.667v.004c.007.134.006.2-.002.266v.08c-.03.007-.056.018-.083.024-.152.055-.274.135-.393.2.012-.09.013-.18.003-.267v-.015c-.012-.133-.04-.2-.082-.333a.613.613 0 00-.166-.267.248.248 0 00-.183-.064h-.021c-.071.006-.13.04-.186.132a.552.552 0 00-.12.27.944.944 0 00-.023.33v.015c.012.135.037.2.08.334.046.134.098.2.166.268.01.009.02.018.034.024-.07.057-.117.07-.176.136a.304.304 0 01-.131.068 2.62 2.62 0 01-.275-.402 1.772 1.772 0 01-.155-.667 1.759 1.759 0 01.08-.668 1.43 1.43 0 01.283-.535c.128-.133.26-.2.418-.2zm1.37 1.706c.332 0 .733.065 1.216.399.293.2.523.269 1.052.468h.003c.255.136.405.266.478.399v-.131a.571.571 0 01.016.47c-.123.31-.516.643-1.063.842v.002c-.268.135-.501.333-.775.465-.276.135-.588.292-1.012.267a1.139 1.139 0 01-.448-.067 3.566 3.566 0 01-.322-.198c-.195-.135-.363-.332-.612-.465v-.005h-.005c-.4-.246-.616-.512-.686-.71-.07-.268-.005-.47.193-.6.224-.135.38-.271.483-.336.104-.074.143-.102.176-.131h.002v-.003c.169-.202.436-.47.839-.601.139-.036.294-.065.466-.065zm2.8 2.142c.358 1.417 1.196 3.475 1.735 4.473.286.534.855 1.659 1.102 3.024.156-.005.33.018.513.064.646-1.671-.546-3.467-1.089-3.966-.22-.2-.232-.335-.123-.335.59.534 1.365 1.572 1.646 2.757.13.535.16 1.104.021 1.67.067.028.135.06.205.067 1.032.534 1.413.938 1.23 1.537v-.002c-.06-.135-.12-.2-.2-.333-.08-.066-.16-.135-.257-.2h-.005c-.141-.066-.293-.135-.381-.271-.12.135-.241.2-.381.266h-.004c-.12.066-.261.2-.443.2.04.135.06.265.039.4v.002c-.04.135-.1.2-.18.335-.16.269-.4.535-.76.733-.38.199-.79.399-1.22.465-.43.066-.9.066-1.4-.066-.057-.019-.117-.036-.18-.06-.14.358-.381.668-.758.899v.002c.298-.135.582-.335.783-.667.067-.135.102-.2.121-.334v-.003c.02-.135.02-.334-.06-.468-.04-.066-.14-.2-.26-.267-.12-.065-.28-.135-.46-.197-.36-.135-.5-.261-.58-.4-.079-.133-.136-.332-.221-.535-.046-.135-.1-.266-.18-.399-.46-.334-.6-.535-.6-.869 0-.135.02-.27.04-.4a1.5 1.5 0 01.14-.4c-.04-.066-.08-.132-.12-.198-.12-.2-.28-.533-.32-.867-.04-.2-.06-.4-.02-.6.02-.2.08-.4.16-.533.16-.27.36-.469.6-.602.24-.135.48-.2.72-.202.12 0 .24.016.36.05v-.001c.12.033.22.066.32.133.66.269 1.16.875 1.4 1.671.12.466.14 1.002-.08 1.336v.002c-.04.066-.08.135-.14.198l.01-.002c.02.002.04.003.06.008.14.033.3.066.46.135l.04.02c-.08-.4-.2-.867-.36-1.2-.26-.604-.681-1.138-1.14-1.337a3.03 3.03 0 00-.42-.135c-.1-.027-.2-.04-.3-.04-.2-.002-.4.033-.58.135-.18.135-.34.27-.42.468-.08.2-.1.402-.08.601.02.2.08.334.16.534.08.201.22.401.4.533.18.135.4.2.62.268.2.066.4.133.6.265v.002c.2.135.32.334.4.602.06.134.08.268.08.4.06.066.16.135.28.198.12.066.26.066.4.066.12 0 .26 0 .4-.066.12-.065.24-.135.36-.268l-.04.268c0 .133-.04.266-.14.398-.08.135-.26.268-.52.4-.26.135-.54.2-.78.266-.24.066-.46.135-.66.268-.2.135-.36.335-.48.668l.04.066v.002a.77.77 0 00.58.2c.2 0 .38-.066.56-.133.18-.066.34-.2.5-.334.16-.132.3-.331.44-.532.18-.2.22-.468.22-.667 0-.135-.02-.265-.06-.4.5-.2.86-.535 1.06-.802.22-.266.36-.533.44-.733.08-.2.08-.334.04-.401 0-.066-.08-.135-.18-.2-.1-.066-.22-.133-.34-.2-.16-.133-.3-.333-.4-.6a4.33 4.33 0 01-.16-.734c-.06-.333-.1-.667-.14-.999-.04-.334-.14-.602-.24-.867-.04-.135-.1-.268-.18-.4-.08-.134-.18-.268-.3-.401-.24-.27-.52-.469-.84-.535-.32-.067-.64-.067-.96.067-.32.133-.6.332-.82.599-.22.268-.36.601-.44.936-.08.266-.12.6-.1.867.02.2.08.4.16.533l-.04-.001zM7.5 14c.6 0 1.1.4 1.1 1s-.5 1-1.1 1c-.6 0-1.1-.4-1.1-1s.5-1 1.1-1zm9 0c.6 0 1.1.4 1.1 1s-.5 1-1.1 1c-.6 0-1.1-.4-1.1-1s.5-1 1.1-1z" />
                </svg>
            ),
            label: t.download.beta,
            labelColor: 'bg-yellow-500',
            fileName: 'HomeCloudServer-Linux.zip',
            downloadUrl: 'https://github.com/abayDahln/Home-Cloud/releases/download/v1.0s/HomeCloudServer-Linux.zip',
            description: 'Portable app for Linux distributions.'
        },
        {
            name: 'Source Code',
            icon: '📦',
            fileName: 'v1.0s.zip',
            downloadUrl: 'https://github.com/abayDahln/Home-Cloud/archive/refs/tags/v1.0s.zip',
            description: 'Backend source code (Requires Golang).'
        }
    ]

    const handleDownload = (index) => {
        const url = platforms[index].downloadUrl
        if (url && url !== '#') window.location.href = url

        setDownloadingStates(prev => ({ ...prev, [index]: true }))
        setTimeout(() => {
            setDownloadingStates(prev => ({ ...prev, [index]: false }))
            setCompletedDownloads(prev => ({ ...prev, [index]: true }))
            setTimeout(() => setCompletedDownloads(prev => ({ ...prev, [index]: false })), 2000)
        }, 2000)
    }

    const handleServerDownload = (index) => {
        const url = serverDownloads[index].downloadUrl
        if (url && url !== '#') window.location.href = url

        setServerDownloading(prev => ({ ...prev, [index]: true }))
        setTimeout(() => {
            setServerDownloading(prev => ({ ...prev, [index]: false }))
            setServerCompleted(prev => ({ ...prev, [index]: true }))
            setTimeout(() => setServerCompleted(prev => ({ ...prev, [index]: false })), 2000)
        }, 2000)
    }

    // Stagger children variants
    const containerV = { hidden: {}, visible: { transition: { staggerChildren: 0.12 } } }
    const glideV = { hidden: { opacity: 0, x: -30 }, visible: { opacity: 1, x: 0, transition: { duration: 0.6, ease: [0.25, 0.1, 0.25, 1] } } }

    return (
        <div className="pt-24 min-h-screen relative overflow-hidden bg-bgWhite">
            {/* 1. Gradient Aura Background */}
            <div className="fixed inset-0 -z-10 overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-white via-blue-50/40 to-gray-100" />
                <motion.div
                    animate={{ backgroundPosition: ['0% 0%', '100% 100%', '0% 0%'] }}
                    transition={{ duration: 60, repeat: Infinity, ease: 'linear' }}
                    className="absolute inset-0 opacity-30"
                    style={{
                        backgroundImage: 'radial-gradient(ellipse at 30% 20%, rgba(147,197,253,0.25) 0%, transparent 60%), radial-gradient(ellipse at 70% 80%, rgba(196,181,253,0.15) 0%, transparent 60%)',
                        backgroundSize: '200% 200%',
                    }}
                />
            </div>

            {/* Hero — Smooth Glide Text Reveal */}
            <section className="py-16 px-6 lg:px-8">
                <motion.div
                    variants={containerV}
                    initial="hidden"
                    animate="visible"
                    className="max-w-screen-2xl mx-auto text-center"
                >
                    <motion.h1 variants={glideV} className="text-4xl md:text-6xl font-extrabold text-textBlack mb-4 tracking-tight">
                        {t.download.title}{' '}
                        <span className="gradient-text">Home Cloud</span>
                    </motion.h1>
                    <motion.p variants={glideV} className="text-lg font-light text-gray max-w-2xl mx-auto">
                        {t.download.subtitle}
                    </motion.p>
                </motion.div>
            </section>

            {/* Platform Cards */}
            <section className="py-12 px-6 lg:px-8">
                <div className="max-w-screen-2xl mx-auto">
                    <motion.div
                        variants={containerV}
                        initial="hidden"
                        animate="visible"
                        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8"
                    >
                        {platforms.map((platform, index) => (
                            <motion.div key={index} variants={glideV}>
                                <TiltCard
                                    onMouseEnter={() => setHoveredCard(index)}
                                    onMouseLeave={() => setHoveredCard(null)}
                                    className={`relative flex flex-col p-6 rounded-2xl transition-shadow duration-500 ${platform.popular
                                        ? 'bg-white border-2 border-primary/30 shadow-xl shadow-primary/10 scale-[1.03]'
                                        : 'bg-white border border-lightGray/60 shadow-lg hover:shadow-xl'
                                        } ${!platform.available ? 'opacity-70' : ''}`}
                                >
                                    {/* Most Picked badge — Highlight Indicator Fade */}
                                    <AnimatePresence>
                                        {platform.popular && (
                                            <motion.div
                                                initial={{ opacity: 0, y: -10 }}
                                                animate={{ opacity: 1, y: 0 }}
                                                transition={{ duration: 0.8, ease: 'easeOut' }}
                                                className="absolute -top-3 left-1/2 -translate-x-1/2 bg-primary text-white text-[10px] font-bold py-1 px-4 rounded-full uppercase tracking-wider shadow-md"
                                            >
                                                Most Picked
                                            </motion.div>
                                        )}
                                        {platform.label && (
                                            <motion.div
                                                initial={{ opacity: 0, scale: 0.8 }}
                                                animate={{ opacity: 1, scale: 1 }}
                                                className={`absolute top-0 right-0 m-4 ${platform.labelColor} text-white text-[10px] font-bold py-1 px-3 rounded-full uppercase tracking-wider shadow-sm z-10`}
                                            >
                                                {platform.label}
                                            </motion.div>
                                        )}
                                    </AnimatePresence>

                                    {/* Category & Name */}
                                    <div className="text-center mb-5 pt-3">
                                        <p className="text-[10px] font-bold text-primary uppercase tracking-[0.2em] mb-1">{platform.category}</p>
                                        <h2 className="text-2xl font-extrabold text-textBlack">{platform.name}</h2>
                                        <p className="text-xs text-gray-light font-light mt-0.5">{platform.version}</p>
                                    </div>

                                    {/* Icon — Breathing Pulse */}
                                    <div className="flex justify-center mb-5">
                                        <motion.div
                                            animate={{ scale: hoveredCard === index ? [1, 1.12, 1] : [1, 1.06, 1] }}
                                            transition={{ duration: hoveredCard === index ? 1.5 : 3, repeat: Infinity, ease: 'easeInOut' }}
                                            className={`p-4 rounded-2xl ${platform.available ? `${platform.iconColor} bg-gray-50` : 'text-gray bg-gray/5'}`}
                                        >
                                            {platform.icon}
                                        </motion.div>
                                    </div>

                                    {/* Size */}
                                    <div className="text-center mb-6">
                                        <span className="text-2xl font-extrabold text-textBlack">{platform.size}</span>
                                        <span className="text-xs text-gray-light font-light block mt-0.5">File Size</span>
                                    </div>

                                    {/* Features — Smooth Glide Reveal on hover */}
                                    <div className="flex-1 mb-6">
                                        <ul className="space-y-2.5">
                                            {platform.features.map((feature, i) => (
                                                <motion.li
                                                    key={i}
                                                    initial={{ opacity: 0, x: -20 }}
                                                    animate={{ opacity: 1, x: 0 }}
                                                    transition={{ delay: index * 0.12 + i * 0.06, duration: 0.5, ease: 'easeOut' }}
                                                    className="flex items-center gap-2.5 text-sm text-gray font-light"
                                                >
                                                    <svg className={`w-4 h-4 flex-shrink-0 ${platform.available ? 'text-green-500' : 'text-gray/40'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                                                    </svg>
                                                    {feature}
                                                </motion.li>
                                            ))}
                                        </ul>
                                    </div>

                                    {/* Download Button — Liquid Fill */}
                                    {platform.available ? (
                                        <AnimatePresence mode="wait">
                                            {completedDownloads[index] ? (
                                                <motion.div
                                                    key="done"
                                                    initial={{ scale: 0.8, opacity: 0 }}
                                                    animate={{ scale: 1, opacity: 1 }}
                                                    exit={{ scale: 0.8, opacity: 0 }}
                                                    className="w-full flex items-center justify-center bg-green-500 text-white font-bold py-3 rounded-xl"
                                                >
                                                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" /></svg>
                                                </motion.div>
                                            ) : downloadingStates[index] ? (
                                                <motion.div key="loading" className="w-full relative bg-primary/10 rounded-xl overflow-hidden h-[44px]">
                                                    <motion.div
                                                        initial={{ height: '0%' }}
                                                        animate={{ height: '100%' }}
                                                        transition={{ duration: 2, ease: 'easeInOut' }}
                                                        className="absolute bottom-0 left-0 right-0 bg-primary rounded-xl"
                                                    />
                                                    <span className="absolute inset-0 flex items-center justify-center text-white font-bold text-sm z-10">
                                                        <motion.span animate={{ opacity: [1, 0.5, 1] }} transition={{ duration: 1, repeat: Infinity }}>Downloading...</motion.span>
                                                    </span>
                                                </motion.div>
                                            ) : (
                                                <motion.button
                                                    key="btn"
                                                    onClick={() => handleDownload(index)}
                                                    whileHover={{ scale: 1.03 }}
                                                    whileTap={{ scale: 0.97 }}
                                                    className="relative w-full overflow-hidden bg-primary text-white font-bold py-3 px-6 rounded-xl group"
                                                >
                                                    {/* Liquid fill from bottom on hover */}
                                                    <span className="absolute inset-0 bg-primary-dark1 translate-y-full group-hover:translate-y-0 transition-transform duration-500 ease-out rounded-xl" />
                                                    <span className="relative z-10">{t.download.download}</span>
                                                </motion.button>
                                            )}
                                        </AnimatePresence>
                                    ) : (
                                        <button disabled className="w-full bg-lightGray text-gray font-bold py-3 px-6 rounded-xl cursor-not-allowed">
                                            {t.download.comingSoon}
                                        </button>
                                    )}
                                </TiltCard>
                            </motion.div>
                        ))}
                    </motion.div>
                </div>
            </section>

            {/* Server Downloads */}
            <section className="py-16 px-6 lg:px-8">
                <div className="max-w-screen-2xl mx-auto">
                    <motion.div initial={{ opacity: 0, x: -30 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} transition={{ duration: 0.6 }} className="text-center mb-10">
                        <h2 className="text-2xl md:text-3xl font-extrabold text-textBlack mb-2">{t.download.serverApp}</h2>
                        <p className="text-gray font-light">{t.download.serverAppDesc}</p>
                    </motion.div>

                    <motion.div
                        variants={containerV}
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8"
                    >
                        {serverDownloads.map((server, index) => (
                            <motion.div key={index} variants={glideV}>
                                <TiltCard
                                    onMouseEnter={() => setServerHovered(index)}
                                    onMouseLeave={() => setServerHovered(null)}
                                    className="relative flex flex-col p-6 rounded-2xl bg-white border border-lightGray/60 shadow-lg hover:shadow-xl transition-shadow duration-500 h-full"
                                >
                                    {server.label && (
                                        <div className={`absolute top-0 right-0 m-4 ${server.labelColor} text-white text-[10px] font-bold py-1 px-3 rounded-full uppercase tracking-wider shadow-sm z-10`}>
                                            {server.label}
                                        </div>
                                    )}
                                    {/* Category & Name */}
                                    <div className="text-center mb-5 pt-3">
                                        <p className="text-[10px] font-bold text-primary uppercase tracking-[0.2em] mb-1">SERVER APP</p>
                                        <h2 className="text-xl font-extrabold text-textBlack">{server.name}</h2>
                                        <p className="text-xs text-gray-light font-light mt-0.5">{server.fileName}</p>
                                    </div>

                                    {/* Icon */}
                                    <div className="flex justify-center mb-5">
                                        <motion.div
                                            animate={{ scale: serverHovered === index ? [1, 1.12, 1] : [1, 1.06, 1] }}
                                            transition={{ duration: serverHovered === index ? 1.5 : 3, repeat: Infinity, ease: 'easeInOut' }}
                                            className="p-4 rounded-2xl bg-gray-50 text-5xl"
                                        >
                                            {server.icon}
                                        </motion.div>
                                    </div>

                                    {/* Description */}
                                    <div className="flex-1 mb-6 text-center">
                                        <p className="text-sm text-gray font-light leading-relaxed">
                                            {server.description}
                                        </p>
                                    </div>

                                    {/* Download Button */}
                                    <div className="mt-auto">
                                        <AnimatePresence mode="wait">
                                            {serverCompleted[index] ? (
                                                <motion.div
                                                    key="done"
                                                    initial={{ scale: 0.8, opacity: 0 }}
                                                    animate={{ scale: 1, opacity: 1 }}
                                                    exit={{ scale: 0.8, opacity: 0 }}
                                                    className="w-full flex items-center justify-center bg-green-500 text-white font-bold py-3 rounded-xl"
                                                >
                                                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" /></svg>
                                                </motion.div>
                                            ) : serverDownloading[index] ? (
                                                <motion.div key="loading" className="w-full relative bg-primary/10 rounded-xl overflow-hidden h-[44px]">
                                                    <motion.div
                                                        initial={{ height: '0%' }}
                                                        animate={{ height: '100%' }}
                                                        transition={{ duration: 2, ease: 'easeInOut' }}
                                                        className="absolute bottom-0 left-0 right-0 bg-primary rounded-xl"
                                                    />
                                                    <span className="absolute inset-0 flex items-center justify-center text-white font-bold text-sm z-10">
                                                        <motion.span animate={{ opacity: [1, 0.5, 1] }} transition={{ duration: 1, repeat: Infinity }}>Downloading...</motion.span>
                                                    </span>
                                                </motion.div>
                                            ) : (
                                                <motion.button
                                                    key="btn"
                                                    onClick={() => handleServerDownload(index)}
                                                    whileHover={{ scale: 1.03 }}
                                                    whileTap={{ scale: 0.97 }}
                                                    className="relative w-full overflow-hidden bg-primary text-white font-bold py-3 px-6 rounded-xl group"
                                                >
                                                    <span className="absolute inset-0 bg-primary-dark1 translate-y-full group-hover:translate-y-0 transition-transform duration-500 ease-out rounded-xl" />
                                                    <span className="relative z-10">{t.download.download}</span>
                                                </motion.button>
                                            )}
                                        </AnimatePresence>
                                    </div>
                                </TiltCard>
                            </motion.div>
                        ))}
                    </motion.div>
                </div>
            </section>

            {/* Requirements */}
            <section className="py-12 px-6 lg:px-8 pb-20">
                <div className="max-w-6xl mx-auto">
                    <motion.h2 initial={{ opacity: 0, x: -30 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} transition={{ duration: 0.6 }} className="text-2xl font-extrabold text-textBlack mb-8 text-center">
                        {t.download.systemReq}
                    </motion.h2>
                    <div className="grid md:grid-cols-2 gap-8">
                        {[{ emoji: '📱', title: t.download.mobileApps, items: t.download.reqMobile, dir: -1 },
                        { emoji: '💻', title: t.download.desktopServer, items: t.download.reqServer, dir: 1 }
                        ].map((section, si) => (
                            <motion.div
                                key={si}
                                initial={{ opacity: 0, x: section.dir * 40 }}
                                whileInView={{ opacity: 1, x: 0 }}
                                viewport={{ once: true }}
                                transition={{ duration: 0.6 }}
                                className="p-6 rounded-2xl bg-white border border-lightGray/60 shadow-lg"
                            >
                                <h3 className="font-extrabold text-textBlack mb-4 flex items-center gap-2 text-lg">
                                    <span className="text-2xl">{section.emoji}</span> {section.title}
                                </h3>
                                <ul className="space-y-2 text-gray font-light text-sm">
                                    {section.items.map((req, i) => (
                                        <motion.li key={i} initial={{ opacity: 0, x: -15 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.08, duration: 0.4 }}>
                                            {req}
                                        </motion.li>
                                    ))}
                                </ul>
                            </motion.div>
                        ))}
                    </div>
                </div>
            </section>
        </div>
    )
}

export default Download
