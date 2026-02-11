import { useState, useEffect } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useLanguage } from '../context/LanguageContext'
import LanguageSwitcher from './LanguageSwitcher'

const Navbar = () => {
    const [isScrolled, setIsScrolled] = useState(false)
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
    const location = useLocation()
    const { t } = useLanguage()

    useEffect(() => {
        const handleScroll = () => {
            setIsScrolled(window.scrollY > 20)
        }
        window.addEventListener('scroll', handleScroll)
        return () => window.removeEventListener('scroll', handleScroll)
    }, [])

    const navLinks = [
        { name: t.nav.home, path: '/' },
        { name: t.nav.about, path: '/about' },
        { name: t.nav.howToUse, path: '/how-to-use' },
        { name: t.nav.download, path: '/download' },
    ]

    return (
        <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${isScrolled ? 'bg-white shadow-lg shadow-black/5' : 'bg-transparent'
            }`}>
            <div className="max-w-screen-2xl mx-auto px-6 lg:px-8">
                <div className="flex items-center justify-between h-20">
                    {/* Logo */}
                    <Link to="/" className="flex items-center gap-3 group">
                        <div className="w-10 h-10 bg-white rounded-xl flex items-center justify-center shadow-lg shadow-black/5 group-hover:shadow-primary/20 transition-all duration-300 overflow-hidden p-1.5">
                            <img src="/src/assets/icon/app_logo.png" alt="HomeCloud Logo" className="w-full h-full object-contain" />
                        </div>
                        <span className="text-xl font-bold text-textBlack">Home Cloud</span>
                    </Link>

                    {/* Desktop Nav Links */}
                    <div className="hidden md:flex items-center gap-8">
                        {navLinks.map((link) => (
                            <Link
                                key={link.path}
                                to={link.path}
                                className={`font-medium transition-colors duration-300 ${location.pathname === link.path
                                    ? 'text-primary'
                                    : 'text-gray hover:text-primary'
                                    }`}
                            >
                                {link.name}
                            </Link>
                        ))}
                    </div>

                    {/* CTA Button & Language Switcher */}
                    <div className="hidden md:flex items-center gap-4">
                        <LanguageSwitcher />
                        <Link to="/download" className="btn-primary">
                            {t.nav.downloadNow}
                        </Link>
                    </div>

                    {/* Mobile Menu Button */}
                    <button
                        className="md:hidden p-2"
                        onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                    >
                        <svg className="w-6 h-6 text-textBlack" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            {isMobileMenuOpen ? (
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                            ) : (
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                            )}
                        </svg>
                    </button>
                </div>

                {/* Mobile Menu */}
                {isMobileMenuOpen && (
                    <div className="md:hidden py-4 border-t border-lightGray">
                        {navLinks.map((link) => (
                            <Link
                                key={link.path}
                                to={link.path}
                                className={`block py-3 font-medium ${location.pathname === link.path ? 'text-primary' : 'text-gray'
                                    }`}
                                onClick={() => setIsMobileMenuOpen(false)}
                            >
                                {link.name}
                            </Link>
                        ))}
                        <div className="py-3 flex items-center justify-between">
                            <span className="text-gray font-medium">Language</span>
                            <LanguageSwitcher />
                        </div>
                        <Link
                            to="/download"
                            className="btn-primary w-full block text-center mt-4"
                            onClick={() => setIsMobileMenuOpen(false)}
                        >
                            {t.nav.downloadNow}
                        </Link>
                    </div>
                )}
            </div>
        </nav>
    )
}

export default Navbar
