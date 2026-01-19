/**
* Name: Simulacion Av Simon Bolivar - VISUAL ORIGINAL + DATA REAL (CSV)
* Author: Jordi, Byron
*/
model simulacion_Si9mon_Bolivar

global {
// --- 1. ARCHIVOS ---
	file archivo_toda_la_red <- file("../includes/red_vial_unificada.shp");
	file archivo_simon_bolivar <- file("../includes/eje_simon_bolivar.shp");
	file barrios_shapefile <- file("../includes/Barrios_Final.shp");
	file archivo_causas <- csv_file("../includes/Causas_GAMA.csv", ";");
	geometry shape <- envelope(archivo_toda_la_red);
	graph road_network;
	map<string, float> probabilidades_causas <- [];
	list<list<float>>
	matriz_riesgo_semanal <- [[0.34, 0.05, 0.05, 0.34, 0.69, 1.03, 1.38, 1.38, 1.03, 1.03, 0.69, 0.34, 0.34, 0.05, 1.03, 1.38, 0.69, 0.69, 1.03, 1.72, 0.05, 0.34, 0.34, 0.05], [0.34, 0.34, 1.03, 0.05, 0.34, 0.05, 1.38, 1.72, 0.69, 0.05, 1.03, 0.69, 0.69, 1.38, 1.03, 0.69, 1.38, 0.69, 1.72, 0.34, 1.03, 0.69, 0.05, 0.34], [0.05, 0.69, 0.34, 0.34, 1.03, 1.03, 1.38, 1.72, 0.69, 1.03, 0.69, 0.34, 0.05, 0.34, 0.69, 1.03, 1.03, 1.38, 1.72, 1.03, 1.38, 0.34, 0.69, 0.34], [0.69, 0.34, 0.05, 0.69, 0.34, 0.34, 2.07, 3.45, 1.03, 2.41, 1.03, 0.69, 0.69, 1.72, 0.34, 1.38, 1.38, 0.34, 1.72, 0.69, 0.69, 2.07, 0.34, 0.34], [0.05, 1.38, 1.38, 0.69, 1.03, 0.34, 2.07, 1.72, 0.69, 0.05, 0.34, 1.03, 0.05, 0.69, 1.72, 1.72, 1.72, 0.34, 1.72, 1.38, 0.34, 1.72, 2.07, 1.38], [1.72, 1.03, 1.03, 2.76, 1.72, 0.34, 1.72, 1.38, 0.69, 2.07, 0.69, 0.34, 1.03, 0.69, 2.07, 1.72, 0.69, 1.38, 1.03, 0.69, 1.38, 1.38, 1.38, 1.03], [0.69, 1.03, 0.69, 0.34, 1.38, 0.05, 1.03, 1.72, 1.03, 0.34, 1.38, 0.69, 1.72, 0.34, 1.03, 0.34, 1.03, 0.05, 0.34, 0.69, 0.05, 0.34, 0.34, 0.34]];
	list<string> nombres_dias <- ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
	list<float> riesgo_mensual <- [0.94, 0.91, 0.78, 0.76, 1.19, 1.06, 1.16, 1.14, 0.71, 1.19, 1.16, 1.00];
	list<float> prob_lluvia_mes <- [0.484, 0.571, 0.645, 0.733, 0.548, 0.333, 0.194, 0.194, 0.367, 0.548, 0.533, 0.516];
	list<int> metas_mensuales <- [37, 36, 31, 30, 47, 42, 46, 45, 28, 47, 46, 40];
	float factor_calibracion_por_accidente <- 0.000000046;
	float factor_velocidad_usuario <- 1.0 min: 0.5 max: 2.0;
	float factor_lluvia_usuario <- 1.0 min: 0.0 max: 3.0;
	float prob_imprudencia_usuario <- 0.4 min: 0.0 max: 1.0;
	int num_vehiculos <- 1500 min: 500 max: 2500;
	float probabilidad_calibrada_base <- 0.0000039;
	int mes_simulacion <- 1 min: 1 max: 12;
	int dias_a_simular <- 31;
	bool lluvia_activa <- false;
	string ruta_csv <- "../results/siniestros_mes_" + mes_simulacion + ".csv";

	// TIEMPO
	int hora_actual <- 6;
	int minuto_actual <- 0;
	int dias_simulados <- 0;
	int dia_semana <- 0;

	// ESTILOS
	rgb color_fondo <- rgb(191, 191, 191);
	bool es_noche <- false;

	// ESTADÍSTICAS
	int total_accidentes <- 0;
	// Contadores para el gráfico visual (agrupados)
	int acc_velocidad <- 0;
	int acc_distancia <- 0;
	int acc_alcohol <- 0;
	int acc_clima <- 0;
	int acc_normal <- 0;
	int acc_imprudencia <- 0;

	// PUNTOS CRÍTICOS
	point punto_ruminahui <- {6391.94, 24177.32};
	point punto_bautista <- {4820.37, 24729.05};
	point punto_interoceanica <- {9644.12, 18905.70};
	point extremo_norte <- {11457.18, 501.91};
	point extremo_sur <- {704.03, 37538.77};

	// MAPA DE CALOR
	list<point> ubicaciones_accidentes <- [];
	int radio_deteccion <- 600;
	int num_celdas_calor <- 150;
	
	// SISTEMA DE LLUVIA
	int num_gotas_lluvia <- 200;
	float intensidad_lluvia <- 0.0;
	
	// SISTEMA DE PARTÍCULAS DE HUMO
	int particulas_por_accidente <- 15;

	init {
		create barrio from: barrios_shapefile with: [nombre::string(read("NOMBRE"))];
		create via_decorativa from: archivo_toda_la_red;
		create via_principal from: archivo_simon_bolivar;
		road_network <- as_edge_graph(via_principal);
		do cargar_causas_desde_csv;
		do crear_trafico_inicial;
		do crear_mapa_calor;
		do crear_gotas_lluvia;
		int meta_del_mes_actual <- metas_mensuales at (mes_simulacion - 1);
		probabilidad_calibrada_base <- meta_del_mes_actual * factor_calibracion_por_accidente;
		write "CALIBRACIÓN: Mes " + mes_simulacion;
		write "Meta de accidentes: " + meta_del_mes_actual;
		write "Probabilidad Base Calculada: " + probabilidad_calibrada_base;
		save ["mes", "dia", "hora", "tipo_vehiculo", "causa_accidente", "x", "y"] to: ruta_csv format: "csv" rewrite: true;
	}

	action cargar_causas_desde_csv {
		if (archivo_causas = nil) {
			return;
		}

		matrix data <- matrix(archivo_causas);
		loop i from: 1 to: data.rows - 1 {
			string nombre_causa <- string(data[0, i]);
			float probabilidad <- float(data[1, i]);
			add probabilidad at: nombre_causa to: probabilidades_causas;
		}

		write "Datos cargados: " + probabilidades_causas;
	}

	action crear_mapa_calor {
		loop i from: 0 to: num_celdas_calor {
			create celda_calor {
				via_principal via_aleatoria <- one_of(via_principal);
				location <- any_location_in(via_aleatoria);
			}

		}

	}

	action crear_trafico_inicial {
		create Moto number: num_vehiculos * 0.12;
		create Auto number: num_vehiculos * 0.60;
		create Camioneta number: num_vehiculos * 0.20;
		create Transporte_Pesado number: num_vehiculos * 0.04;
		create Bus number: num_vehiculos * 0.035;
		create Bicicleta number: num_vehiculos * 0.005;
	}
	
	action crear_gotas_lluvia {
		create gota_lluvia number: num_gotas_lluvia;
	}

	reflex control_tiempo_y_clima {
		minuto_actual <- minuto_actual + 5;
		if (minuto_actual >= 60) {
			minuto_actual <- 0;
			hora_actual <- hora_actual + 1;
			if (hora_actual >= 24) {
				hora_actual <- 0;
				dias_simulados <- dias_simulados + 1;
				dia_semana <- dia_semana + 1;
				if (dia_semana > 6) {
					dia_semana <- 0;
				}

				if (dias_simulados >= dias_a_simular) {
					write "------------------------------------------------------";
					write "FIN DE SIMULACIÓN (" + dias_simulados + ")";
					write "Total Accidentes: " + total_accidentes;
					write "Resultados guardados en: " + ruta_csv;
					write "------------------------------------------------------";
					do pause;
				}

			}

			// Inercia de Lluvia
			float chance_base <- prob_lluvia_mes at (mes_simulacion - 1);
			float chance_actual <- chance_base * factor_lluvia_usuario;
			if (lluvia_activa) {
				chance_actual <- chance_actual + 0.30;
			} else {
				chance_actual <- chance_actual - 0.10;
			}

			if (flip(chance_actual)) {
				lluvia_activa <- true;
			} else {
				lluvia_activa <- false;
			}

		}

		if (hora_actual >= 19 or hora_actual <= 5) {
			es_noche <- true;
			color_fondo <- rgb(20, 20, 30);
		} else {
			es_noche <- false;
			color_fondo <- lluvia_activa ? rgb(180, 180, 200) : rgb(240, 240, 240);
		}
		
		// Actualizar intensidad de lluvia
		if (lluvia_activa) {
			intensidad_lluvia <- min(1.0, intensidad_lluvia + 0.05);
		} else {
			intensidad_lluvia <- max(0.0, intensidad_lluvia - 0.05);
		}

	}

}

// --- VISUALIZACIÓN (MEJORADA Y LIMPIA) ---

// SISTEMA DE PARTÍCULAS DE HUMO
species particula_humo {
	float vida <- 1.0; // 1.0 = recién creada, 0.0 = desaparece
	float velocidad_x <- rnd(-30.0, 30.0);
	float velocidad_y <- rnd(-50.0, -20.0);
	float tamano_inicial <- rnd(20.0, 40.0);
	
	reflex dispersar {
		// Mover partícula
		location <- location + {velocidad_x, velocidad_y};
		
		// Reducir velocidad (fricción)
		velocidad_x <- velocidad_x * 0.95;
		velocidad_y <- velocidad_y * 0.95;
		
		// Reducir vida
		vida <- vida - 0.02;
		
		// Eliminar cuando desaparece
		if (vida <= 0.0) {
			do die;
		}
	}
	
	aspect default {
		if (vida > 0.0) {
			// Humo gris que se expande y desvanece
			float tamano_actual <- tamano_inicial * (1.5 - vida * 0.5);
			int alpha <- int(255 * vida * 0.6);
			rgb color_humo <- rgb(80, 80, 80, alpha);
			draw circle(tamano_actual) color: color_humo border: rgb(0,0,0,0);
		}
	}
}

// SISTEMA DE GOTAS DE LLUVIA
species gota_lluvia {
	float velocidad_caida <- rnd(50.0, 150.0);
	float tamano <- rnd(6.0, 15.0);
	float opacidad <- rnd(0.3, 0.7);
	point posicion_inicial;
	
	init {
		location <- {rnd(world.shape.width), rnd(world.shape.height)};
		posicion_inicial <- location;
	}
	
	reflex caer {
		if (intensidad_lluvia > 0.1) {
			// Mover la gota hacia abajo
			location <- location + {rnd(-2.0, 2.0), velocidad_caida * intensidad_lluvia};
			
			// Si sale del mundo, reiniciar arriba
			if (location.y > world.shape.height) {
				location <- {rnd(world.shape.width), -10.0};
				velocidad_caida <- rnd(50.0, 150.0);
				tamano <- rnd(3.0, 8.0);
				opacidad <- rnd(0.3, 0.7);
			}
		} else {
			// Si no llueve, mantener gotas invisibles arriba
			location <- {rnd(world.shape.width), -100.0};
		}
	}
	
	aspect default {
		if (intensidad_lluvia > 0.1) {
			// Dibujar gota como línea vertical semi-transparente
			rgb color_gota <- rgb(200, 220, 255, int(255 * opacidad * intensidad_lluvia));
			draw line([location, location + {0, tamano * 2}]) color: color_gota width: 1.5;
		}
	}
}

species celda_calor {
	float intensidad <- 0.0;
	rgb color_calor;
	float tamano_circulo <- 0.0;

	reflex actualizar_intensidad {
		intensidad <- 0.0;
		loop accidente over: ubicaciones_accidentes {
			float distancia <- location distance_to accidente;
			if (distancia < radio_deteccion) {
				intensidad <- intensidad + (1.0 - (distancia / radio_deteccion));
			}

		}

		if (intensidad = 0.0) {
			color_calor <- rgb(0, 0, 0, 0);
			tamano_circulo <- 0.0;
		} else if (intensidad < 0.5) {
			color_calor <- rgb(255, 255, 100, 120);
			tamano_circulo <- 80.0;
		} else if (intensidad < 1.2) {
			color_calor <- rgb(255, 220, 0, 160);
			tamano_circulo <- 120.0;
		} else if (intensidad < 2.5) {
			color_calor <- rgb(255, 150, 0, 180);
			tamano_circulo <- 180.0;
		} else if (intensidad < 4.0) {
			color_calor <- rgb(255, 80, 0, 200);
			tamano_circulo <- 250.0;
		} else {
			color_calor <- rgb(255, 0, 0, 230);
			tamano_circulo <- 350.0;
		} }

	aspect default {
		if (tamano_circulo > 0) {
			draw circle(tamano_circulo) color: color_calor border: rgb(0, 0, 0, 0);
		}

	} }

species via_decorativa {

	aspect default {
	// Líneas más sutiles y finas para el fondo
		if (es_noche) {
			draw shape color: rgb(60, 60, 70) width: 0.5; // Gris oscuro sutil de noche
		} else {
			draw shape color: rgb(220, 220, 220) width: 1.0; // Gris muy claro de día
		}

	}

}

species via_principal {

	aspect default {
	// --- SOLUCIÓN A LOS CORTES ---
	// Se elimina el estilo de tres capas que causaba la fragmentación.
	// Se usa un estilo de carretera de asfalto continua y sólida.
		rgb color_via <- es_noche ? rgb(40, 40, 50) : rgb(100, 100, 110); // Asfalto oscuro/claro
		rgb color_borde <- es_noche ? rgb(20, 20, 30) : rgb(80, 80, 90);

		// Dibujamos la vía como una sola cinta ancha con un borde sutil
		draw shape color: color_via width: 25.0 border: color_borde;
	}

}

species barrio {
	string nombre;

	aspect default {
	// Barrios más transparentes y sutiles para que el mapa se vea más limpio
		draw shape color: es_noche ? rgb(10, 10, 20, 30) : rgb(240, 240, 245, 40) border: es_noche ? rgb(30, 30, 40, 50) : rgb(200, 200, 210, 80);
	}

}

species Vehiculo skills: [moving] {
	float velocidad_base;
	float velocidad_real;
	rgb color_base;
	point objetivo;
	float tamano_dibujo;
	bool es_imprudente <- false;
	bool no_respeta_distancia <- flip(0.20);
	bool es_ebrio <- false;
	bool chocado <- false;
	point last_location;
	int cont_atascado <- 0;
	
	// Variables para efectos visuales
	float velocidad_anterior <- 0.0;
	bool esta_frenando <- false;

	init {
		location <- one_of(via_principal).location;
		last_location <- location;
		if (location distance_to extremo_norte < location distance_to extremo_sur) {
			objetivo <- extremo_sur;
		} else {
			objetivo <- extremo_norte;
		}

		heading <- (location towards objetivo);
		if (dia_semana >= 4) {
			if (flip(0.05)) {
				es_ebrio <- true;
			}

		} else {
			if (flip(0.01)) {
				es_ebrio <- true;
			}

		}

	}

	reflex moverse {
		if (chocado) {
			velocidad_real <- 0.0;
			return;
		}

		if (flip(prob_imprudencia_usuario)) {
			es_imprudente <- true;
		} else {
			es_imprudente <- false;
		}

		velocidad_real <- velocidad_base * factor_velocidad_usuario;
		if (es_imprudente) {
			velocidad_real <- velocidad_real * 1.3;
		}

		if (es_ebrio) {
			velocidad_real <- velocidad_real * 1.5;
		}

		if (lluvia_activa) {
			float penalizacion <- 0.8 - (factor_lluvia_usuario * 0.1);
			if (penalizacion < 0.4) {
				penalizacion <- 0.4;
			}

			velocidad_real <- velocidad_real * penalizacion;
		}

		if (velocidad_real < velocidad_anterior * 0.7 or cont_atascado > 2) {
			esta_frenando <- true;
		} else {
			esta_frenando <- false;
		}
		
		do goto target: objetivo on: road_network speed: velocidad_real;
		velocidad_anterior <- velocidad_real;
		if (last_location != nil) {
			if (location distance_to last_location < 1.0) {
				cont_atascado <- cont_atascado + 1;
			} else {
				cont_atascado <- 0;
			}

		}

		last_location <- location;
		if (cont_atascado > 10) {
			do respawn;
		}

		if (location distance_to objetivo < 500.0) {
			do respawn;
		}

	}

	action respawn {
		cont_atascado <- 0;
		location <- one_of(via_principal).location;
		last_location <- location;
		if (location distance_to extremo_norte < location distance_to extremo_sur) {
			objetivo <- extremo_sur;
		} else {
			objetivo <- extremo_norte;
		}

	}

	reflex calcular_accidente {
		if (chocado) {
			return;
		}

		via_principal via_cercana <- via_principal closest_to location;
		if (via_cercana = nil) {
			return;
		}

		if (location distance_to via_cercana > 50.0) {
			return;
		}

		float f_semana <- (matriz_riesgo_semanal at dia_semana) at hora_actual;
		// float f_mes <- riesgo_mensual at (mes_simulacion - 1); // YA NO SE USA
		float f_clima <- 1.0;
		if (lluvia_activa) {
			f_clima <- 1.0 + (0.4 * factor_lluvia_usuario);
		}

		float f_velocidad <- factor_velocidad_usuario ^ 2;
		float probabilidad <- probabilidad_calibrada_base * f_semana * f_clima * f_velocidad;
		if (location distance_to punto_ruminahui < 300.0 or location distance_to punto_bautista < 300.0 or location distance_to punto_interoceanica < 300.0) {
			probabilidad <- probabilidad * 3.5;
		}

		if (es_imprudente) {
			probabilidad <- probabilidad * 1.5;
		}

		if (no_respeta_distancia and !empty(Vehiculo at_distance 50.0)) {
			probabilidad <- probabilidad * 2.0;
		}

		if (es_ebrio) {
			probabilidad <- probabilidad * 4.0;
		}

		if (flip(probabilidad)) {
			do registrar_choque;
		}

	}

	action registrar_choque {
		chocado <- true;
		total_accidentes <- total_accidentes + 1;
		ubicaciones_accidentes <- ubicaciones_accidentes + location;
		
		// Crear partículas de humo en el lugar del accidente
		loop i from: 0 to: particulas_por_accidente {
			create particula_humo {
				location <- myself.location;
			}
		}
		string causa_real <- rnd_choice(probabilidades_causas);
		if ((causa_real contains "LLUVIA" or causa_real contains "ATMOSFÉRICAS") and !lluvia_activa) {
			causa_real <- "CONDUCIR VEHÍCULO SUPERANDO LOS LÍMITES MÁXIMOS DE VELOCIDAD.";
		}

		if (causa_real contains "VELOCIDAD") {
			acc_velocidad <- acc_velocidad + 1;
		} else if (causa_real contains "DISTANCIA") {
			acc_distancia <- acc_distancia + 1;
		} else if (causa_real contains "ALCOHOL") {
			acc_alcohol <- acc_alcohol + 1;
		} else if (causa_real contains "LLUVIA" or causa_real contains "ATMOSFÉRICAS") {
			acc_clima <- acc_clima + 1;
		} else if (causa_real contains "IMPERICIA" or causa_real contains "CELULAR" or causa_real contains "ATENTO") {
			acc_imprudencia <- acc_imprudencia + 1;
		} else {
			acc_normal <- acc_normal + 1;
		}

		save [mes_simulacion, dias_simulados, hora_actual, species(self), causa_real, int(location.x), int(location.y)] to: ruta_csv format: "csv" rewrite: false;
		write "ACCIDENTE #" + total_accidentes + " - " + causa_real;
	}

	aspect default {
		// Uso location directamente para una visualización más estable
		if (chocado) {
			draw circle(80) color: rgb(255, 0, 0, 200) border: #white at: location;
		} else {
			// Vehículos ligeramente más pequeños para mejorar la escala visual
			draw circle(tamano_dibujo * 0.8) color: color_base at: location;
			draw triangle(tamano_dibujo * 0.5) color: #white rotate: heading + 90 border: color_base at: location;
			
			// EFECTO 1: FAROS DELANTEROS (solo de noche)
			if (es_noche) {
				// Cono de luz amarilla frente al vehículo
				point pos_faro <- location + {cos(heading) * tamano_dibujo * 1.5, sin(heading) * tamano_dibujo * 1.5};
				draw circle(tamano_dibujo * 2.0) color: rgb(255, 255, 150, 40) at: pos_faro;
				draw circle(tamano_dibujo * 1.0) color: rgb(255, 255, 200, 80) at: pos_faro;
			}
			
			// EFECTO 2: LUCES DE FRENO (cuando está frenando)
			if (esta_frenando) {
				// Dos luces rojas en la parte trasera
				point pos_trasera <- location - {cos(heading) * tamano_dibujo * 0.6, sin(heading) * tamano_dibujo * 0.6};
				float offset_lateral <- tamano_dibujo * 0.3;
				
				// Luz izquierda
				point luz_izq <- pos_trasera + {-sin(heading) * offset_lateral, cos(heading) * offset_lateral};
				draw circle(4.0) color: rgb(255, 0, 0, 200) at: luz_izq;
				
				// Luz derecha
				point luz_der <- pos_trasera - {-sin(heading) * offset_lateral, cos(heading) * offset_lateral};
				draw circle(4.0) color: rgb(255, 0, 0, 200) at: luz_der;
			}
		}
	}
}

	// Reduje ligeramente los tamaños de los vehículos para una vista más limpia
species Auto parent: Vehiculo {

	init {
		velocidad_base <- 90.0 #km / #h;
		color_base <- #cyan;
		tamano_dibujo <- 16.0;
	}

}

species Moto parent: Vehiculo {

	init {
		velocidad_base <- 90.0 #km / #h;
		color_base <- #orange;
		tamano_dibujo <- 10.0;
	}

}

species Camioneta parent: Vehiculo {

	init {
		velocidad_base <- 90.0 #km / #h;
		color_base <- #blue;
		tamano_dibujo <- 22.0;
	}

}

species Bus parent: Vehiculo {

	init {
		velocidad_base <- 70.0 #km / #h;
		color_base <- #yellow;
		tamano_dibujo <- 35.0;
	}

}

species Transporte_Pesado parent: Vehiculo {

	init {
		velocidad_base <- 70.0 #km / #h;
		color_base <- #purple;
		tamano_dibujo <- 45.0;
	}

}

species Bicicleta parent: Vehiculo {

	init {
		velocidad_base <- 30.0 #km / #h;
		color_base <- #white;
		tamano_dibujo <- 8.0;
	}

}

experiment Simulacion_SimonBolivar type: gui {
	parameter "Factor Velocidad (1.0 = Real)" var: factor_velocidad_usuario category: "Controles Dinámicos";
	parameter "Factor Lluvia (1.0 = Real)" var: factor_lluvia_usuario category: "Controles Dinámicos";
	parameter "Imprudencia (0.4 = Real)" var: prob_imprudencia_usuario category: "Controles Dinámicos";
	parameter "Mes del Año (1-12)" var: mes_simulacion category: "Configuración Temporal";
	parameter "Densidad Tráfico" var: num_vehiculos category: "Tráfico";
	output {
		monitor "Días Simulados" value: dias_simulados;
		monitor "Día Semana" value: nombres_dias at dia_semana;
		monitor "Hora" value: hora_actual;
		monitor "Total Accidentes" value: total_accidentes;
		monitor "Lluvia Activa" value: lluvia_activa;
		monitor "Vehículos" value: length(Vehiculo);
		monitor "Hora Completa" value: (hora_actual < 10 ? "0" + hora_actual : "" + hora_actual) + ":" + (minuto_actual < 10 ? "0" + minuto_actual : "" + minuto_actual);
		monitor "Mes" value: mes_simulacion;
		layout #split;
		display mapa type: opengl background: color_fondo {
			species barrio;
			species via_decorativa;
			species via_principal;
			species celda_calor;
			species gota_lluvia; // Gotas de lluvia animadas
			species particula_humo; // Humo de accidentes
			species Auto;
			species Moto;
			species Camioneta;
			species Bus;
			species Bicicleta;
			species Transporte_Pesado;
			graphics "Puntos Negros" {
				draw circle(300) color: rgb(0, 0, 0, 0) border: #red at: punto_ruminahui;
				draw circle(300) color: rgb(0, 0, 0, 0) border: #red at: punto_bautista;
				draw circle(300) color: rgb(0, 0, 0, 0) border: #red at: punto_interoceanica;
				draw "Int. Rumiñahui" at: punto_ruminahui color: es_noche ? #white : #black font: font("Arial", 5, #bold);
				draw "J.B. Aguirre" at: punto_bautista color: es_noche ? #white : #black font: font("Arial", 5, #bold);
				draw "Interoceánica" at: punto_interoceanica color: es_noche ? #white : #black font: font("Arial", 5, #bold);
			}

			overlay position: {5, 5} size: {380 #px, 220 #px} background: es_noche ? rgb(20, 20, 40, 230) : rgb(255, 255, 255, 240) border: es_noche ? rgb(100, 150, 255) : rgb(50, 100, 200) rounded: true {
				float y <- 20.0;
				rgb txt <- es_noche ? #white : #black;
				
				draw "SIMULACION EN VIVO" at: {10 #px, y #px} color: es_noche ? rgb(100, 200, 255) : rgb(0, 100, 200) font: font("Arial", 14, #bold) anchor: #top_left;
				
				y <- y + 30.0;
				draw "Mes: " + mes_simulacion + " | Dia: " + (dias_simulados + 1) at: {15 #px, y #px} color: txt font: font("Arial", 11, #plain) anchor: #top_left;
				
				y <- y + 25.0;
				string hora_fmt <- (hora_actual < 10 ? "0" : "") + hora_actual + ":" + (minuto_actual < 10 ? "0" : "") + minuto_actual;
				draw (nombres_dias at dia_semana) + " " + hora_fmt at: {15 #px, y #px} color: txt font: font("Arial", 11, #plain) anchor: #top_left;
				
				y <- y + 30.0;
				rgb color_acc <- total_accidentes > 20 ? #red : (total_accidentes > 10 ? #orange : #green);
				draw "Accidentes: " + total_accidentes at: {15 #px, y #px} color: color_acc font: font("Arial", 12, #bold) anchor: #top_left;
				
				y <- y + 30.0;
				string clima_txt <- lluvia_activa ? "LLUVIA" : (es_noche ? "NOCHE" : "DESPEJADO");
				rgb color_clima <- lluvia_activa ? rgb(50, 150, 255) : (es_noche ? rgb(150, 150, 200) : rgb(255, 200, 0));
				draw "Clima: " + clima_txt at: {15 #px, y #px} color: color_clima font: font("Arial", 11, #bold) anchor: #top_left;
				
				y <- y + 25.0;
				draw "Vehiculos: " + length(Vehiculo) at: {15 #px, y #px} color: txt font: font("Arial", 10, #plain) anchor: #top_left;
				
				y <- y + 25.0;
				rgb color_vel <- factor_velocidad_usuario > 1.5 ? #red : (factor_velocidad_usuario > 1.0 ? #orange : #green);
				draw "Velocidad: " + factor_velocidad_usuario + "x" at: {15 #px, y #px} color: color_vel font: font("Arial", 10, #bold) anchor: #top_left;
			}

		}

		display Causas_Siniestro background: #white {
			chart "Causas del Siniestro" type: pie {
				data "Velocidad" value: acc_velocidad color: #blue;
				data "Distancia" value: acc_distancia color: #skyblue;
				data "Alcohol" value: acc_alcohol color: #orange;
				data "Clima" value: acc_clima color: #gray;
				data "Imprudencia/Celular" value: acc_imprudencia color: #purple;
				data "Otros/Azar" value: acc_normal color: #green;
			}
		}

		display Acumulado_vs_Meta background: #white {
			chart "Acumulado vs Meta Mes" type: series y_range: {0, 100} {
				data "Simulación" value: total_accidentes color: #red style: line thickness: 2.0;
				data "Meta Validación" value: (dias_simulados * 1.25) color: #green style: line;
			}
		}

	}

}