import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProductEntity } from '../../database/entities/product.entity';
import { ShoppingService } from './shopping.service';
import { ShoppingController } from './shopping.controller';

@Module({
  imports: [TypeOrmModule.forFeature([ProductEntity])],
  controllers: [ShoppingController],
  providers: [ShoppingService],
  exports: [ShoppingService],
})
export class ShoppingModule {}
