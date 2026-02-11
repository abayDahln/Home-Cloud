import { Link } from 'react-router-dom'

const Footer = () => {
    return (
        <footer className="bg-white border-t border-lightGray">
            <div className="max-w-screen-2xl mx-auto px-6 lg:px-8 py-12">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                    {/* Brand */}
                    <div className="md:col-span-2">
                        <Link to="/" className="flex items-center gap-3 mb-4">
                            <div className="w-10 h-10 bg-white rounded-xl flex items-center justify-center p-1.5 shadow-sm border border-black/5">
                                <img src="/src/assets/icon/app_logo.png" alt="HomeCloud Logo" className="w-full h-full object-contain" />
                            </div>
                            <span className="text-xl font-bold text-textBlack">HomeCloud</span>
                        </Link>
                        <p className="text-gray max-w-md">
                            Your personal cloud storage solution. Access your files anywhere, anytime, from any device.
                        </p>
                    </div>

                    {/* Links */}
                    <div>
                        <h4 className="font-semibold text-textBlack mb-4">Quick Links</h4>
                        <ul className="space-y-2">
                            <li><Link to="/" className="text-gray hover:text-primary transition-colors">Home</Link></li>
                            <li><Link to="/about" className="text-gray hover:text-primary transition-colors">About</Link></li>
                            <li><Link to="/download" className="text-gray hover:text-primary transition-colors">Download</Link></li>
                        </ul>
                    </div>

                    {/* Platforms */}
                    <div>
                        <h4 className="font-semibold text-textBlack mb-4">Platforms</h4>
                        <ul className="space-y-2">
                            <li><span className="text-gray">Android</span></li>
                            <li><span className="text-gray">iOS</span></li>
                            <li><span className="text-gray">Windows</span></li>
                            <li><span className="text-gray">Linux</span></li>
                        </ul>
                    </div>
                </div>

                <div className="border-t border-lightGray mt-12 pt-8 text-center">
                    <p className="text-gray text-sm">
                        © {new Date().getFullYear()} HomeCloud. All rights reserved.
                    </p>
                </div>
            </div>
        </footer>
    )
}

export default Footer
