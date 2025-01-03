import { Montserrat } from 'next/font/google';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import React from 'react';
const montserrat = Montserrat({ subsets: ['latin'] });

export default function Navbar(): React.ReactElement {
    const router = useRouter();

    return (
        <nav className="fixed top-0 w-full text-gray-100 z-10 bg-gray-900/80 backdrop-blur-sm">
            <div className="px-4 sm:px-8 flex justify-between items-center h-16">
                <Link href="/" className={`text-3xl font-extrabold tracking-tight ${montserrat.className}`}>
                    <span className="text-blue-300">Crush</span>{' '}
                    <span className="text-blue-500">Your Race</span>
                </Link>
                <button
                    className="px-4 py-2 text-gray-200 bg-gray-900 font-semibold rounded-3xl flex space-x-2 outline outline-2 outline-gray-200 hover:scale-105 hover:shadow-lg transition duration-300 ease-in-out"
                    onClick={() => router.push('/dashboard')}
                >
                    <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    <span>Dashboard</span>
                </button>
            </div>
        </nav>
    );
}
