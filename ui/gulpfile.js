/*
 * Copyright 2018 - 2021 Swiss Federal Institute of Technology Lausanne (EPFL)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * This open source software code was developed in part or in whole in the
 * Human Brain Project, funded from the European Union's Horizon 2020
 * Framework Programme for Research and Innovation under
 * Specific Grant Agreements No. 720270, No. 785907, and No. 945539
 * (Human Brain Project SGA1, SGA2 and SGA3).
 *
 */

const gulp = require('gulp'),
    concat = require('gulp-concat'),
    riot = require('gulp-riot'),
    gulpif = require('gulp-if'),
    webserver = require('gulp-webserver'),
    minify = require('gulp-minify');

gulp.task('build', function (done) {
    gulp.src(['src/js/lib/*.js',
            'src/js/RiotPolice.js',
            'src/js/RiotStore.js',
            'src/js/store/*.js',
            'src/tag/**/*.tag',
            'src/js/AppConfig.js',
            'src/js/App.js'
        ])
        .pipe(gulpif("*.tag", riot()))
        .pipe(concat('bundle.js'))
        /*.pipe(minify({
            ext:{min:'.min.js'}
        }))*/
        .pipe(gulp.dest('./build/'));

    gulp.src('src/index.html').pipe(gulp.dest('./build/'))
    gulp.src('src/img/**/*.*').pipe(gulp.dest('./build/img/'))
    done();
});

gulp.task('default', function (done) {
    gulp.watch('src/**/*', gulp.series('build'));
    gulp.src('./build/')
        .pipe(webserver({
            directoryListing: {
                enable: true,
                path: "./build/"
            },
            open: "http://localhost:8000/index.html",
            port: 8000,
            proxies: [{
                    source: "/api/",
                    target: "https://stats.kg-dev.ebrains.eu/api/"
                }
            ]
        }));
    done();
});