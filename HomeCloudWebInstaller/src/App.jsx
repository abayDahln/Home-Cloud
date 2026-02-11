import { Routes, Route, useLocation } from 'react-router-dom'
import { useEffect } from 'react'
import Navbar from './components/Navbar'
import Footer from './components/Footer'
import Landing from './pages/Landing'
import About from './pages/About'
import Download from './pages/Download'
import HowToUse from './pages/HowToUse'
import { LanguageProvider } from './context/LanguageContext'

function ScrollToTop() {
    const { pathname } = useLocation()
    useEffect(() => {
        window.scrollTo(0, 0)
    }, [pathname])
    return null
}

function App() {
    return (
        <LanguageProvider>
            <ScrollToTop />
            <div className="min-h-screen bg-bgWhite flex flex-col">
                <Navbar />
                <main className="flex-1">
                    <Routes>
                        <Route path="/" element={<Landing />} />
                        <Route path="/about" element={<About />} />
                        <Route path="/download" element={<Download />} />
                        <Route path="/how-to-use" element={<HowToUse />} />
                    </Routes>
                </main>
                <Footer />
            </div>
        </LanguageProvider>
    )
}

export default App
