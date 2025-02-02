'use client';

import { AnimatePresence, motion } from 'framer-motion';
import React, { useEffect, useState } from 'react';

type CarouselPage = {
    image: string;
    title: string;
    subtitle: string;
};

const pages: CarouselPage[] = [
    {
        image: "/Dashboard.png",
        title: "Next Gen Training",
        subtitle: "Our AI curates your week and gives you feedback daily"
    },
    {
        image: "/DashboardAlt.png",
        title: "Achieve Your Goals",
        subtitle: "Training plans updated weekly based on your training history"
    },
    {
        image: "/Profile.png",
        title: "Tailored For You",
        subtitle: "Customize your preferences to get the most out of your training"
    }
];

export default function ImageCarousel(): React.ReactElement {
    const [currentPage, setCurrentPage] = useState(0);

    useEffect(() => {
        const isLargeScreen = window.matchMedia('(min-width: 640px)').matches;
        if (isLargeScreen) return;

        const timer = setInterval(() => {
            setCurrentPage((prev) => (prev + 1) % pages.length);
        }, 5000);
        return () => clearInterval(timer);
    }, []);

    return (
        <div className="flex justify-center w-full">
            <div className="w-full max-w-[1000px]">
                <div className="hidden md:grid md:grid-cols-2 lg:grid-cols-3 md:gap-y-8 md:gap-x-4 px-4 justify-items-center">
                    {pages.map((page, index) => (
                        <div key={index} className={`group relative w-full md:max-w-[450px] lg:max-w-none ${pages.length === 3 && index === 2 ? 'md:col-span-2 lg:col-span-1' : ''}`}>
                            <div className="relative flex items-center justify-center">
                                <div className="relative w-full rounded-2xl overflow-hidden">
                                    <img
                                        src={page.image}
                                        alt={page.title}
                                        className="w-full h-auto"
                                    />
                                    <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent" />
                                </div>
                            </div>
                            <div className="absolute bottom-6 left-6 right-6">
                                <h3 className="text-2xl font-semibold text-white mb-2">
                                    {page.title}
                                </h3>
                                <p className="text-gray-200 text-sm">
                                    {page.subtitle}
                                </p>
                            </div>
                        </div>
                    ))}
                </div>

                <div className="md:hidden">
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={currentPage}
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            transition={{ duration: 0.5 }}
                            className="relative h-[32rem] flex items-center justify-center"
                        >
                            <div className="relative w-fit rounded-2xl overflow-hidden">
                                <img
                                    src={pages[currentPage].image}
                                    alt={pages[currentPage].title}
                                    className="max-h-[32rem] w-auto"
                                />
                                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent" />
                            </div>
                            <div className="absolute bottom-6 left-6 right-6 text-center">
                                <h3 className="text-2xl font-semibold text-white mb-2">
                                    {pages[currentPage].title}
                                </h3>
                                <p className="text-gray-200 text-sm">
                                    {pages[currentPage].subtitle}
                                </p>
                            </div>
                        </motion.div>
                    </AnimatePresence>

                    <div className="mt-4 flex justify-center space-x-2">
                        {pages.map((_, index) => (
                            <button
                                key={index}
                                onClick={() => setCurrentPage(index)}
                                className={`h-1.5 rounded-full transition-all duration-300 ${currentPage === index ? 'w-6 bg-blue-500' : 'w-2 bg-gray-300'
                                    }`}
                            />
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}