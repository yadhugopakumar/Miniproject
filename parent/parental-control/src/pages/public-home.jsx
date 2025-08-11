import React, { useState, useEffect } from 'react';
import { Link } from "react-router-dom";
import { Heart, Clock, Users, Shield, CheckCircle, Phone, Mail, MapPin } from 'lucide-react';

export default function PublicHome({ session }) {
  const [isVisible, setIsVisible] = useState({});

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setIsVisible(prev => ({
              ...prev,
              [entry.target.id]: true
            }));
          }
        });
      },
      { threshold: 0.1 }
    );

    const elements = document.querySelectorAll('[data-animate]');
    elements.forEach((el) => observer.observe(el));

    return () => observer.disconnect();
  }, []);

  const features = [
    {
      icon: <Clock className="w-12 h-12 text-green-600" />,
      title: "Active Medication Reminders",
      description: "Never miss a dose with customized medication alerts and schedules"
    },
    {
      icon: <Users className="w-12 h-12 text-green-600" />,
      title: "Parental Controls",
      description: "Configure medication needs, alerts, and settings tailored for your child"
    },
    {
      icon: <Heart className="w-12 h-12 text-green-600" />,
      title: "Usage Reports",
      description: "Track adherence and compliance over time with easy-to-read reports"
    },
    {
      icon: <Shield className="w-12 h-12 text-green-600" />,
      title: "Emergency Contacts",
      description: "Quick access to important contacts for emergency situations"
    }
  ];

  const useCases = [
    "Busy parents managing children's medication schedules",
    "Caregivers ensuring consistent medication routines",
    "Health professionals monitoring pediatric medication compliance",
    "Families with complex medication requirements"
  ];

  const steps = [
    {
      number: "1",
      title: "Create an account",
      description: "Simple registration for parents and caregivers"
    },
    {
      number: "2",
      title: "Add medication profiles",
      description: "Input your child's prescriptions and schedules"
    },
    {
      number: "3",
      title: "Start managing",
      description: "Receive reminders and track compliance"
    }
  ];

  return (

    <div className="min-h-screen bg-gradient-to-br from-green-50 to-white font-sans antialiased">
      {/* Header */}
      <header className="bg-green-600 shadow-lg relative z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <h1 className="text-3xl font-bold text-white">MedRemind</h1>

          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative overflow-hidden bg-gradient-to-r from-green-100 to-green-50 pt-16 pb-20">
        <div className="max-w-6xl mx-auto px-6 text-center">
          <div
            id="hero-heading"
            data-animate
            className={`transform transition-all duration-1000 ${isVisible['hero-heading'] ? 'translate-y-0 opacity-100' : 'translate-y-8 opacity-0'
              }`}
          >
            <h2 className="text-4xl md:text-5xl font-bold text-gray-800 mb-6 leading-tight">
              Welcome to <span className="text-green-600">MedRemind</span>
            </h2>
          </div>

          <div
            id="hero-subtitle"
            data-animate
            className={`transform transition-all duration-1000 delay-300 ${isVisible['hero-subtitle'] ? 'translate-y-0 opacity-100' : 'translate-y-8 opacity-0'
              }`}
          >
            <p className="text-xl md:text-2xl text-gray-600 mb-10 max-w-4xl mx-auto leading-relaxed">
              Monitor and manage your child's medication reminders with comprehensive parental controls
            </p>
          </div>

          {!session && (
            <div
              id="hero-buttons"
              data-animate
              className={`transform transition-all duration-1000 delay-500 ${isVisible['hero-buttons'] ? 'translate-y-0 opacity-100' : 'translate-y-8 opacity-0'
                } flex flex-col sm:flex-row gap-6 justify-center`}
            >
              <Link
                to="/login"
                className="bg-green-600 hover:bg-green-700 text-white px-8 py-4 rounded-xl text-lg font-semibold transform hover:scale-105 transition-all duration-300 shadow-lg hover:shadow-xl"
              >
                Sign In
              </Link>
              <Link
                to="/register"
                className="border-2 border-green-600 text-green-600 hover:bg-green-600 hover:text-white px-8 py-4 rounded-xl text-lg font-semibold transform hover:scale-105 transition-all duration-300" style={{ backgroundColor: "rgb(199, 252, 199)", color: "green" }}
              >
                Sign Up
              </Link>
            </div>
          )}
        </div>
      </section>

      {/* What is MedRemind */}
      <section className="py-20 bg-white">
        <div className="max-w-4xl mx-auto px-6">
          <div
            id="about-section"
            data-animate
            className={`transform transition-all duration-1000 ${isVisible['about-section'] ? 'translate-x-0 opacity-100' : '-translate-x-12 opacity-0'
              }`}
          >
            <h3 className="text-4xl font-bold text-gray-800 mb-8 text-center">What is MedRemind?</h3>
            <p className="text-xl text-gray-600 leading-relaxed text-center max-w-3xl mx-auto">
              MedRemind is a parental control dashboard that helps families keep track of children's medication schedules,
              ensuring timely reminders and better health management for peace of mind.
            </p>
          </div>
        </div>
      </section>

      {/* Key Features */}
      <section className="py-20 bg-gradient-to-br from-green-50 to-white">
        <div className="max-w-6xl mx-auto px-6">
          <h3 className="text-4xl font-bold text-gray-800 mb-16 text-center">Key Features</h3>
          <div className="grid md:grid-cols-2 lg:grid-cols-2 gap-8">
            {features.map((feature, index) => (
              <div
                key={index}
                id={`feature-${index}`}
                data-animate
                className={`bg-white p-8 rounded-2xl shadow-lg hover:shadow-xl transform transition-all duration-700 hover:scale-105 ${isVisible[`feature-${index}`]
                  ? 'translate-y-0 opacity-100'
                  : 'translate-y-12 opacity-0'
                  }`}
                style={{ transitionDelay: `${index * 150}ms` }}
              >
                <div className="flex flex-col items-center text-center">
                  <div className="mb-6 p-4 bg-green-100 rounded-full">
                    {feature.icon}
                  </div>
                  <h4 className="text-2xl font-semibold text-gray-800 mb-4">{feature.title}</h4>
                  <p className="text-lg text-gray-600 leading-relaxed">{feature.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Who Should Use */}
      <section className="py-20 bg-white">
        <div className="max-w-4xl mx-auto px-6">
          <h3 className="text-4xl font-bold text-gray-800 mb-16 text-center">Who Should Use MedRemind?</h3>
          <div className="space-y-6">
            {useCases.map((useCase, index) => (
              <div
                key={index}
                id={`usecase-${index}`}
                data-animate
                className={`flex items-center bg-green-50 p-6 rounded-xl transform transition-all duration-700 ${isVisible[`usecase-${index}`]
                  ? 'translate-x-0 opacity-100'
                  : 'translate-x-8 opacity-0'
                  }`}
                style={{ transitionDelay: `${index * 200}ms` }}
              >
                <CheckCircle className="w-8 h-8 text-green-600 mr-4 flex-shrink-0" />
                <p className="text-xl text-gray-700">{useCase}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Getting Started */}
      {!session && (
        <section className="py-20 bg-gradient-to-br from-green-50 to-white">
          <div className="max-w-5xl mx-auto px-6">
            <h3 className="text-4xl font-bold text-gray-800 mb-16 text-center">Getting Started</h3>
            <div className="grid md:grid-cols-3 gap-8 mb-12">
              {steps.map((step, index) => (
                <div
                  key={index}
                  id={`step-${index}`}
                  data-animate
                  className={`text-center transform transition-all duration-700 ${isVisible[`step-${index}`]
                    ? 'scale-100 opacity-100'
                    : 'scale-95 opacity-0'
                    }`}
                  style={{ transitionDelay: `${index * 300}ms` }}
                >
                  <div className="bg-green-600 text-white w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6 animate-pulse">
                    {step.number}
                  </div>
                  <h4 className="text-2xl font-semibold text-gray-800 mb-4">{step.title}</h4>
                  <p className="text-lg text-gray-600 leading-relaxed">{step.description}</p>
                </div>
              ))}
            </div>

            <div className="text-center">
              <p className="mb-6 max-w-xl mx-auto text-gray-700 text-xl">
                Sign up now, create your child's medication profiles, and start receiving personalized reminders and reports.
              </p>
              <Link
                to="/signup"
                className="inline-block bg-green-600 hover:bg-green-700 text-white py-4 px-10 rounded-xl text-xl font-semibold transform hover:scale-105 transition-all duration-300 shadow-lg hover:shadow-xl"
              >
                Create an Account
              </Link>
            </div>
          </div>
        </section>
      )}

      {/* Footer */}
      <footer
        id="footer"
        data-animate
        className={`bg-gradient-to-r from-green-600 to-green-700 text-white py-16 transform transition-all duration-1000 ${isVisible['footer'] ? 'translate-y-0 opacity-100' : 'translate-y-8 opacity-0'
          }`}
      >
        <div className="max-w-6xl mx-auto px-6">
          <div className="grid md:grid-cols-3 gap-8 text-center md:text-left">
            <div>
              <h3 className="text-2xl font-bold mb-4">MedRemind</h3>
              <p className="text-green-100 text-lg leading-relaxed">
                Keeping families healthy and connected, one reminder at a time
              </p>
            </div>
            <div>
              <h4 className="text-xl font-semibold mb-4">Quick Links</h4>
              <ul className="space-y-2 text-green-100">
                <li><a href="#" className="hover:text-white transition-colors text-lg">About</a></li>
                <li><a href="#" className="hover:text-white transition-colors text-lg">Features</a></li>
                <li><a href="#" className="hover:text-white transition-colors text-lg">Support</a></li>
                <li><a href="#" className="hover:text-white transition-colors text-lg">Privacy</a></li>
              </ul>
            </div>
            <div>
              <h4 className="text-xl font-semibold mb-4">Contact</h4>
              <div className="space-y-3 text-green-100">
                <div className="flex items-center justify-center md:justify-start">
                  <Phone className="w-5 h-5 mr-3" />
                  <span className="text-lg">1-800-MEDREMIND</span>
                </div>
                <div className="flex items-center justify-center md:justify-start">
                  <Mail className="w-5 h-5 mr-3" />
                  <span className="text-lg">support@medremind.com</span>
                </div>
                <div className="flex items-center justify-center md:justify-start">
                  <MapPin className="w-5 h-5 mr-3" />
                  <span className="text-lg">Available Nationwide</span>
                </div>
              </div>
            </div>
          </div>
          <div className="border-t border-green-500 mt-12 pt-8 text-center">
            <p className="text-green-100 text-lg">© 2024 MedRemind. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>

  );
}