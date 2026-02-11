import { motion } from 'framer-motion'
import { useLanguage } from '../context/LanguageContext'

const LanguageSwitcher = () => {
    const { language, toggleLanguage } = useLanguage()

    return (
        <button
            onClick={toggleLanguage}
            className="relative inline-flex items-center h-8 rounded-full w-16 bg-lightGray p-1 transition-colors focus:outline-none"
            aria-label="Toggle Language"
        >
            <motion.div
                className="w-6 h-6 bg-white rounded-full shadow-md flex items-center justify-center text-xs font-bold text-primary z-10"
                layout
                transition={{ type: "spring", stiffness: 700, damping: 30 }}
                style={{
                    marginLeft: language === 'en' ? '0' : 'auto',
                    marginRight: language === 'en' ? 'auto' : '0'
                }}
            >
                {language.toUpperCase()}
            </motion.div>
            <span className="absolute left-2 text-[10px] font-bold text-gray">EN</span>
            <span className="absolute right-2 text-[10px] font-bold text-gray">ID</span>
        </button>
    )
}

export default LanguageSwitcher
