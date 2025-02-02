'use client';

import { motion } from 'framer-motion';
import { Inter, Montserrat } from 'next/font/google';
import Image from 'next/image';
import React from 'react';
import Footer from './components/Footer';
import ImageCarousel from './components/ImageCarousel';
import Navbar from './components/Navbar';

const inter = Inter({ subsets: ['latin'] });
const montserrat = Montserrat({ subsets: ['latin'] });

const APP_STORE_URL: string = "https://apps.apple.com/us/app/crush-your-race/id6737172627";

export default function Home(): React.ReactElement {

  const testimonials: Array<{ name: string; quote: string; image: string }> = [
    {
      name: "Danny Lio",
      quote: "The training plan adapts to my performance in real-time. It's like having an elite coach watching every run.",
      image: "/danny-lio.png"
    },
    {
      name: "Jared Palek",
      quote: "I used to pay $50/month for a human coach. This is more personalized and a fraction of the cost!",
      image: "/jared-palek.png"
    },
    {
      name: "Rachel Decker",
      quote: "The Strava integration is seamless - my plan updates automatically after every run. It's truly intelligent coaching.",
      image: "/rachel-decker.png"
    },
  ];

  const fadeInUp = {
    initial: { opacity: 0, y: 20 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.6 }
  };

  return (
    <div className="bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 text-gray-100 min-h-screen overflow-hidden">
      <Navbar />
      <main className="container mx-auto px-6 py-24 sm:px-8 lg:px-12 relative">
        <motion.div
          className="text-center mb-32 relative"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1 }}
        >
          <div className="glow glow-blue" />
          <h1 className={`text-5xl sm:text-6xl md:text-7xl font-extrabold tracking-tight mb-8 mt-12 ${montserrat.className}`}>
            <span className="text-blue-300">Crush</span>{' '}
            <span className="text-blue-500">Your Race</span>
          </h1>
          <p className={`text-2xl sm:text-3xl text-gray-100 mb-16 ${inter.className}`}>
            Your AI Running Coach That Gets Smarter With Every Run
          </p>

          <motion.button
            className="px-8 py-4 text-xl text-gray-200 bg-blue-600 font-bold rounded-full hover:bg-blue-700 transition duration-300 ease-in-out shadow-lg hover:shadow-blue-500/50 inline-flex items-center justify-center gap-3"
            onClick={() => window.open(APP_STORE_URL, '_blank')}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <Image
              src="/favicon.png"
              alt="Download on App Store"
              width={24}
              height={24}
            />
            Download on App Store
          </motion.button>
        </motion.div>

        <motion.section
          className="mb-24 relative glass-section rounded-2xl p-12 gradient-dark"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
        >
          <ImageCarousel />
        </motion.section>

        <motion.section
          className="mb-24 relative glass-section rounded-2xl p-12 gradient-blue"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
        >
          <div className="glow glow-blue opacity-10" />
          <div className="max-w-7xl mx-auto">
            <h2 className="text-5xl font-bold mb-16 text-center">
              Building the <span className="text-blue-400">Future</span> of Running
            </h2>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-16">
              <motion.div
                className="relative"
                {...fadeInUp}
                transition={{ delay: 0.1 }}
              >
                <div className="absolute -top-8 left-0">
                  <span className="text-blue-400 text-8xl font-bold opacity-10">01</span>
                </div>
                <div className="space-y-4">
                  <h3 className="text-3xl font-bold text-blue-300">Vertical AI Expertise</h3>
                  <div className="h-1 w-20 bg-blue-500"></div>
                  <p className="text-xl leading-relaxed text-gray-300">
                    While others build generic AI, we're laser-focused on running. Our specialized intelligence evolves with every stride you take, delivering coaching that's light years ahead.
                  </p>
                </div>
              </motion.div>

              <motion.div
                className="relative"
                {...fadeInUp}
                transition={{ delay: 0.2 }}
              >
                <div className="absolute -top-8 left-0">
                  <span className="text-blue-400 text-8xl font-bold opacity-10">02</span>
                </div>
                <div className="space-y-4">
                  <h3 className="text-3xl font-bold text-blue-300">Beyond Human Limits</h3>
                  <div className="h-1 w-20 bg-blue-500"></div>
                  <p className="text-xl leading-relaxed text-gray-300">
                    AI will surpass human coaching capabilities in the next 5 years. We're already providing truly personalized training at a scale no human coach can match.
                  </p>
                </div>
              </motion.div>

              <motion.div
                className="relative"
                {...fadeInUp}
                transition={{ delay: 0.3 }}
              >
                <div className="absolute -top-8 left-0">
                  <span className="text-blue-400 text-8xl font-bold opacity-10">03</span>
                </div>
                <div className="space-y-4">
                  <h3 className="text-3xl font-bold text-blue-300">Democratizing Elite Training</h3>
                  <div className="h-1 w-20 bg-blue-500"></div>
                  <p className="text-xl leading-relaxed text-gray-300">
                    Elite-level guidance shouldn't be exclusive. As AI costs plummet, we're making world-class training accessible to every runner on the planet.
                  </p>
                </div>
              </motion.div>
            </div>
          </div>
        </motion.section>

        <motion.section
          className="mb-24 relative glass-section rounded-2xl p-8 gradient-purple"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
        >
          <div className="glow glow-blue -top-1/2 right-0 opacity-10" />
          <div className="glow glow-purple bottom-0 left-0 opacity-10" />

          <div className="text-center max-w-4xl mx-auto">
            <motion.div
              initial={{ scale: 0.9 }}
              whileInView={{ scale: 1 }}
              transition={{ duration: 0.5 }}
            >
              <h3 className="sm:text-5xl text-4xl font-bold mb-8">
                <span className="line-through text-gray-400">$5 per month</span>
              </h3>
              <div className="sm:text-6xl text-4xl font-extrabold mb-12 bg-gradient-to-r from-green-400 to-blue-500 text-transparent bg-clip-text">
                Free for a limited time!
              </div>
            </motion.div>

            <div className="bg-gray-800/30 backdrop-blur-lg sm:p-12 p-8 rounded-2xl border border-gray-700/50 shadow-2xl">
              <ul className="space-y-6 text-left sm:text-2xl text-lg mb-12">
                <li className="flex items-center gap-3">
                  <svg className="w-6 h-6 text-green-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  <span>AI-powered personalized training plans</span>
                </li>
                <li className="flex items-center gap-3">
                  <svg className="w-6 h-6 text-green-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  <span>Automatic Strava integration & real-time updates</span>
                </li>
                <li className="flex items-center gap-3">
                  <svg className="w-6 h-6 text-green-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  <span>Dynamic adjustments based on your performance</span>
                </li>
                <li className="flex items-center gap-3">
                  <svg className="w-6 h-6 text-green-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  <span>Elite-level coaching at a fraction of the cost</span>
                </li>
              </ul>

              <motion.button
                className="px-8 py-4 text-xl text-gray-500 bg-gray-200 font-bold rounded-full hover:bg-gray-300 hover:scale-105 transition duration-300 ease-in-out shadow-lg hover:shadow-blue-500/50 inline-flex items-center justify-center gap-3 mx-auto"
                onClick={() => window.open(APP_STORE_URL, '_blank')}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <Image
                  src="/favicon.png"
                  alt="Download on App Store"
                  width={24}
                  height={24}
                />
                Download Now
              </motion.button>
            </div>
          </div>
        </motion.section>

        <motion.section
          className="mb-24 relative glass-section rounded-2xl p-12 gradient-blue"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
        >
          <div className="glow glow-purple opacity-10" />
          <div className="text-center mb-24">
            <h2 className="text-4xl font-bold mb-12">What Our Users Say</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-12 max-w-7xl mx-auto">
              {testimonials.map((testimonial, index) => (
                <motion.div
                  key={index}
                  className="bg-gray-800 p-8 rounded-lg flex flex-col items-center text-center"
                  {...fadeInUp}
                  transition={{ delay: index * 0.1 }}
                >
                  <div className="mb-6 relative w-36 h-36 overflow-hidden rounded-full border-4 border-blue-500">
                    <Image
                      src={testimonial.image}
                      alt={testimonial.name}
                      width={144}
                      height={144}
                      quality={100}
                      priority
                    />
                  </div>
                  <p className="italic mb-6 text-xl">&ldquo;{testimonial.quote}&rdquo;</p>
                  <p className="font-semibold text-lg text-blue-300">- {testimonial.name}</p>
                </motion.div>
              ))}
            </div>
          </div>
        </motion.section>

        <motion.div
          className="text-center mb-24 relative"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1 }}
        >
          <div className="glow glow-blue" />
          <h2 className="text-4xl font-bold mb-8">Ready to Experience the Future of Running?</h2>
          <motion.button
            className="px-10 py-5 text-2xl text-gray-200 bg-blue-600 font-bold rounded-full hover:bg-blue-700 transition duration-300 ease-in-out shadow-lg hover:shadow-blue-500/50 inline-flex items-center justify-center gap-3 mx-auto"
            onClick={() => window.open(APP_STORE_URL, '_blank')}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <Image
              src="/favicon.png"
              alt="Download on App Store"
              width={24}
              height={24}
            />
            Download on App Store
          </motion.button>
        </motion.div>
      </main>
      <Footer />
    </div>
  );
}
