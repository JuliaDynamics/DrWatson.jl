# The logos main font is Top one is Bernard Condensed;
# the subtitle font is Gill Sans.
# Discussion for the logo is done in issue #20:
# https://github.com/JuliaDynamics/DrWatson.jl/issues/20

using Luxor

function bowler()
    move(Point(-5., 135.9))
    curve(Point(38.5, 135.9), Point(81.3, 135.7), Point(125., 132.9))
    curve(Point(142.5, 132.3), Point(159.2, 130.1), Point(176.7, 129.2))
    curve(Point(183.5, 128.5), Point(191.4, 127.7), Point(198.5, 126.2))
    curve(Point(201.6, 125.5), Point(203.8, 123.2), Point(206.6, 122.8))
    curve(Point(208.6, 120.2), Point(209.5, 118.5), Point(210.2, 116.6))
    curve(Point(210.2, 119.7), Point(214.7, 112.6), Point(216.5, 110.7))
    curve(Point(221.7, 103.5), Point(223.0, 97.7), Point(214.7, 94.7))
    curve(Point(202.4, 90.3), Point(190.5, 89.5), Point(178.5, 87.9))
    curve(Point(177.6, 87.7), Point(167.9, 85.5), Point(166.6, 82.6))
    curve(Point(165.5, 74.2), Point(167.9, 65.2), Point(165.6, 56.2))
    curve(Point(164.2, 46.6), Point(166.2, 36.7), Point(164.8, 26.5))
    curve(Point(163.5, -4.2), Point(159.6, -31.9), Point(147.7, -59.7))
    curve(Point(142.7, -69.5), Point(136.7, -81.4), Point(129., -89.6))
    curve(Point(112.4, -106.2), Point(90.5, -117.6), Point(68.5, -125.4))
    curve(Point(46.4, -133.3), Point(26.0, -139.4), Point(2.4, -139.4))
    curve(Point(-21.6, -139.4), Point(-47.5, -133.3), Point(-69.5, -125.4))
    curve(Point(-91.6, -117.6), Point(-113.2, -106.2), Point(-130.5, -89.6))
    curve(Point(-137.5, -81.4), Point(-143.2, -69.5), Point(-148.9, -59.7))
    curve(Point(-160.7, -31.9), Point(-165.5, -4.2), Point(-166.4, 26.5))
    curve(Point(-167.8, 36.7), Point(-167.9, 46.6), Point(-167.3, 56.2))
    curve(Point(-168.5, 65.2), Point(-165.2, 74.2), Point(-168.3, 82.6))
    curve(Point(-169.6, 85.5), Point(-178.2, 87.7), Point(-179.5, 87.9))
    curve(Point(-191.6, 89.5), Point(-203.4, 90.3), Point(-215., 94.7))
    curve(Point(-224.7, 97.7), Point(-223.4, 103.5), Point(-217.5, 110.7))
    curve(Point(-215.4, 112.6), Point(-211.9, 119.7), Point(-211.9, 116.6))
    curve(Point(-210.6, 118.5), Point(-209.2, 120.2), Point(-207.2, 122.8))
    curve(Point(-204.5, 123.2), Point(-202.7, 125.5), Point(-199.4, 126.2))
    curve(Point(-192., 127.7), Point(-184.6, 128.5), Point(-177.4, 129.2))
    curve(Point(-132.7, 133.5), Point(-117.7, 133.), Point(-72.7, 134.4))
    curve(Point(-55.4, 134.9), Point(-37.4, 135.5), Point(-19.7, 135.9))
    curve(Point(-14.9, 136.2), Point(-10.0, 135.7), Point(-5., 135.9))
end

function moustache()
    move(Point(-2.5, -24.5))
    curve(Point(-2.5, -24.5), Point(9.5, -37.), Point(27.5, -37.))
    curve(Point(44.4, -37.), Point(78.4, 0.1), Point(85.6, 5.5))
    curve(Point(91.3, 10.4), Point(120.4, 42.4), Point(140.7, 41.6))
    curve(Point(161.2, 40.2), Point(168.5, 37.6), Point(179.2, 34.6))
    curve(Point(191.6, 32.6), Point(158.7, 55.2), Point(143.7, 64.7))
    curve(Point(128.6, 73.6), Point(102.6, 77.2), Point(81.2, 73.6))
    curve(Point(60.4, 69.5), Point(33.7, 52.4), Point(21.8, 43.1))
    curve(Point(10.6, 35.6), Point(-2.5, 23.6), Point(-2.5, 23.6))
    curve(Point(-2.5, 23.6), Point(-15.7, 35.6), Point(-26.9, 43.1))
    curve(Point(-38.7, 52.4), Point(-65.5, 69.5), Point(-86.4, 73.6))
    curve(Point(-107.4, 77.2), Point(-133.7, 73.6), Point(-148.3, 64.7))
    curve(Point(-163.7, 55.2), Point(-196.4, 32.6), Point(-184.3, 34.6))
    curve(Point(-173.6, 37.6), Point(-166.1, 40.2), Point(-145.2, 41.6))
    curve(Point(-125.5, 42.4), Point(-96.4, 10.4), Point(-90.7, 5.5))
    curve(Point(-83.4, 0.1), Point(-49.5, -37.), Point(-32.6, -37.))
    curve(Point(-14.6, -37.), Point(-2.5, -24.5), Point(-2.5, -24.5))
end

function finalversion(fname)
    s = 500
    Drawing(s, s, fname)
    background(0, 0, 0, 0)
    setopacity(1.0)
    origin()
    squircle(O, 250, 250, rt = 0.15, :clip)
    table = Table(1, 3, s//3, s)
    for (pos, n) in table
        sethue([Luxor.lighter_green, Luxor.lighter_red, Luxor.lighter_purple][n])
        box(table, n, :fill)
    end
    sethue("black")
    fontsize(8)
    @layer begin
        translate(0, -100)
        bowler()
        fillpath()
    end
    @layer begin
        translate(0, 140)
        moustache()
        fillpath()
    end
    finish()
    preview()
end

cd(@__DIR__)
finalversion("src/assets/logo.png")
