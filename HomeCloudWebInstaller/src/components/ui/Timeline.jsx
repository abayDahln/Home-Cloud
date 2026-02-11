import { useScroll, useTransform, motion, useSpring, useMotionValueEvent } from "framer-motion";
import React, { useEffect, useRef, useState } from "react";

export const Timeline = ({ data }) => {
    const ref = useRef(null);
    const containerRef = useRef(null);
    const [height, setHeight] = useState(0);
    const [activeIndex, setActiveIndex] = useState(-1);
    const checkpointRefs = useRef([]);

    useEffect(() => {
        if (ref.current) {
            const rect = ref.current.getBoundingClientRect();
            setHeight(rect.height);
        }
    }, [ref, data]);

    const { scrollYProgress } = useScroll({
        target: containerRef,
        offset: ["start 10%", "end 50%"],
    });

    const heightTransform = useTransform(scrollYProgress, [0, 1], [0, height]);
    const opacityTransform = useTransform(scrollYProgress, [0, 0.1], [0, 1]);

    const smoothHeight = useSpring(heightTransform, {
        stiffness: 500,
        damping: 90,
        mass: 1
    });

    // Track which checkpoints have been reached
    useMotionValueEvent(smoothHeight, "change", (latest) => {
        if (!ref.current || !checkpointRefs.current.length) return;
        const containerTop = ref.current.getBoundingClientRect().top + window.scrollY;

        let newActive = -1;
        checkpointRefs.current.forEach((cp, i) => {
            if (!cp) return;
            const cpTop = cp.getBoundingClientRect().top + window.scrollY;
            const relativePos = cpTop - containerTop;
            // Activate when the line reaches (or passes) the checkpoint
            if (latest >= relativePos - 20) {
                newActive = i;
            }
        });

        if (newActive !== activeIndex) {
            setActiveIndex(newActive);
        }
    });

    return (
        <div
            className="w-full font-sans md:px-10 overflow-hidden"
            ref={containerRef}
        >
            <div className="max-w-screen-2xl mx-auto px-4 md:px-8 lg:px-10">
                <div ref={ref} className="relative max-w-screen-2xl mx-auto pb-0">
                    {/* Atmospheric Background Effects */}
                    <div className="absolute inset-0 pointer-events-none overflow-hidden">
                        <div className="absolute -left-20 top-40 h-[500px] w-[500px] bg-primary/5 rounded-full blur-[100px]" />
                        <div className="absolute -right-20 bottom-40 h-[500px] w-[500px] bg-primary-light2/5 rounded-full blur-[100px]" />
                    </div>

                    {data.map((item, index) => {
                        const isActive = index <= activeIndex;
                        const justActivated = index === activeIndex;

                        return (
                            <div
                                key={index}
                                className="flex justify-start pt-20 md:pt-40 md:gap-10 relative group"
                            >
                                {/* Checkpoint marker */}
                                <div
                                    className="sticky flex flex-col md:flex-row z-40 items-center top-40 self-start max-w-xs lg:max-w-sm md:w-full"
                                >
                                    <div
                                        ref={(el) => (checkpointRefs.current[index] = el)}
                                        className="h-10 absolute left-3 md:left-3 w-10 flex items-center justify-center z-50"
                                    >
                                        {/* Outer ring — animates on activation */}
                                        <motion.div
                                            animate={isActive ? {
                                                scale: [1, 1.3, 1],
                                                boxShadow: justActivated
                                                    ? ["0 0 0 0px rgba(37,99,235,0.4)", "0 0 0 12px rgba(37,99,235,0)", "0 0 0 0px rgba(37,99,235,0)"]
                                                    : "0 0 0 0px rgba(37,99,235,0)"
                                            } : { scale: 1 }}
                                            transition={justActivated ? { duration: 0.6, ease: "easeOut" } : { duration: 0.3 }}
                                            className={`absolute inset-0 rounded-full transition-colors duration-500 ${isActive
                                                ? 'bg-white border-2 border-primary shadow-lg shadow-primary/30'
                                                : 'bg-white border border-lightGray shadow-md'
                                                }`}
                                        />

                                        {/* Inner dot */}
                                        <motion.div
                                            animate={isActive ? { scale: 1, opacity: 1 } : { scale: 0.6, opacity: 0.4 }}
                                            transition={{ type: "spring", stiffness: 300, damping: 15 }}
                                            className={`relative w-4 h-4 rounded-full z-10 ${isActive
                                                ? 'bg-gradient-to-br from-primary to-primary-dark1'
                                                : 'bg-gray-light/50'
                                                }`}
                                        >
                                            {/* Continuous pulse when active */}
                                            {isActive && (
                                                <motion.div
                                                    animate={{
                                                        boxShadow: ["0 0 0 0px rgba(37,99,235,0.4)", "0 0 0 8px rgba(37,99,235,0)"]
                                                    }}
                                                    transition={{ duration: 2, repeat: Infinity, ease: "easeOut" }}
                                                    className="absolute inset-0 rounded-full bg-primary"
                                                />
                                            )}
                                        </motion.div>
                                    </div>

                                    {/* Step title */}
                                    <motion.h3
                                        initial={{ opacity: 0, x: -20 }}
                                        whileInView={{ opacity: 1, x: 0 }}
                                        viewport={{ once: true, margin: "-100px" }}
                                        transition={{ duration: 0.8, ease: "easeOut" }}
                                        className={`hidden md:block text-xl md:pl-20 md:text-5xl font-bold tracking-tight transition-colors duration-500 ${isActive ? 'text-primary/70' : 'text-gray-light/30'
                                            }`}
                                    >
                                        {item.title}
                                    </motion.h3>
                                </div>

                                {/* Content Section */}
                                <div className="relative pl-20 pr-4 md:pl-4 w-full">
                                    <motion.h3
                                        initial={{ opacity: 0, x: -20 }}
                                        whileInView={{ opacity: 1, x: 0 }}
                                        viewport={{ once: true }}
                                        className={`md:hidden block text-2xl mb-4 text-left font-bold transition-colors duration-500 ${isActive ? 'text-primary/70' : 'text-gray-light/50'
                                            }`}
                                    >
                                        {item.title}
                                    </motion.h3>
                                    <motion.div
                                        initial={{ opacity: 0, y: 50, filter: "blur(10px)" }}
                                        whileInView={{ opacity: 1, y: 0, filter: "blur(0px)" }}
                                        viewport={{ once: true, margin: "-10%" }}
                                        transition={{ duration: 0.8, delay: 0.1, ease: "easeOut" }}
                                    >
                                        {item.content}
                                    </motion.div>
                                </div>
                            </div>
                        );
                    })}

                    {/* Vertical Line Container */}
                    <div
                        style={{ height: height + "px" }}
                        className="absolute md:left-8 left-8 top-0 overflow-hidden w-[2px] bg-slate-200"
                    >
                        {/* Filling Line */}
                        <motion.div
                            style={{
                                height: smoothHeight,
                                opacity: opacityTransform,
                            }}
                            className="absolute inset-x-0 top-0 w-[2px] bg-gradient-to-b from-primary via-primary-light2 to-primary rounded-full shadow-[0_0_15px_rgba(37,99,235,0.6)]"
                        />
                    </div>

                    {/* Moving dot that follows the progress line */}
                    <motion.div
                        style={{
                            top: smoothHeight,
                            opacity: opacityTransform,
                        }}
                        className="absolute left-[29px] md:left-[29px] w-3 h-3 -translate-x-[1px] -translate-y-1/2 z-30"
                    >
                        <div className="w-full h-full rounded-full bg-primary shadow-lg shadow-primary/50" />
                        <motion.div
                            animate={{
                                scale: [1, 2, 1],
                                opacity: [0.6, 0, 0.6],
                            }}
                            transition={{ duration: 1.5, repeat: Infinity, ease: "easeOut" }}
                            className="absolute inset-0 rounded-full bg-primary"
                        />
                    </motion.div>
                </div>
            </div>
        </div>
    );
};
